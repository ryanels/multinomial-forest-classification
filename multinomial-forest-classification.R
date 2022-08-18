######################################
# Ryan Elson
#
######################################
library(dplyr)


### (A). Data Preparation 
## Read Data 
path = "/ForestTypes"
rawtrain <- read.table(file= paste0(getwd(), path, '/training.csv'), sep = ",", header = TRUE)
rawtest <- read.table(file= paste0(getwd(), path, '/testing.csv'), sep = ",", header = TRUE)
data <- rbind(rawtrain, rawtest)
#oversample classes h and o 
data_ho <- data %>% filter(grepl("h|o", class))
data<- rbind(data, data_ho)

n <- nrow(data)
n1 <- round(n*.2)

## Split to training and testing subset 
set.seed(123)
flag <- sort(sample(n,n1, replace = FALSE))
traindata <- data[-flag,]
testdata<- data[flag,]

## Extract the true response value for training and testing data
y1_train    <- as.numeric(as.factor(traindata$class))
y2_test    <- as.numeric(as.factor(testdata$class))

## (B) Boosting 
library(gbm)  #boosting library
library(caret)
#
#Gbm library doesn't seem to work for multinomial classification problem
#will use caret package for gbm instead
#
#gbm.forest <- gbm(as.factor(class) ~ .,data=traindata,
#                 n.trees = 5000, 
#                 shrinkage = 0.01, 
#                 interaction.depth = 3,
#                 cv.folds = 10)

metric <- "Kappa"
trainControl <- trainControl(method="cv", number=10)
grid <- expand.grid(interaction.depth = 3,
                    n.trees = seq(1,5000), 
                    shrinkage = .01,
                    n.minobsinnode = 5) # you can also put something        like c(5, 10, 15, 20)
gbm.forest <- train(as.factor(class) ~ .
                   , data=traindata
                   , distribution="multinomial"
                   , method="gbm"
                   , trControl=trainControl
                   , verbose=FALSE
                   , tuneGrid=grid
                   , metric=metric
)                 

## Model Inspection 
## Find the estimated optimal number of iterations(for gbm package. doesn't work for multinomial)
#perf_gbm1 = gbm.perf(gbm.forest, method="cv") 
#perf_gbm1

#For the caret package
plot(gbm.forest)
perf_gbm1 <- which.max(gbm.forest$results$Kappa)   #get index of max accuracy
max(gbm.forest$results$Kappa)         #max accuracy value

## summary model
## Which variances are important
summary(gbm.forest)

## Make Prediction
## use "predict" to find the training or testing error

## Training error
pred1gbm <- predict(gbm.forest,newdata = traindata[,-1], n.trees=perf_gbm1, type="prob")
#predclass <- colnames(pred1gbm)[max.col(pred1gbm, ties.method = "first")]  #get predicted class/column name

y1hat <- max.col(pred1gbm)  #get column number with max probability
sum(y1hat != y1_train)/length(y1_train)  ##Training error 

## Testing Error
pred2gbm <- predict(gbm.forest,newdata = testdata[,-1], n.trees=perf_gbm1, type="prob")
y2hat <- max.col(pred2gbm)  #get column number with max probability
te0 <- mean(y2hat != y2_test) ## Testing error 

confusionMatrix(as.factor(y2hat), as.factor(y2_test))

## A comparison with other methods using CV
## Testing errors of several algorithms on the dataset:

library(nnet)
library(MASS)
library(e1071)
library(rpart)

#set up 
B= 100; ### number of loops
TEALL = NULL; ### Final TE values
te1<- te2<-te3<- te4<-te5<- c()

for (b in 1:B){
  #pick random 80/20 train/test split
  flag <- sort(sample(n,n1, replace = FALSE))
  traindata <- data[-flag,]
  testdata<- data[flag,]
  y1_train    <- as.numeric(as.factor(traindata$class))
  y2_test    <- as.numeric(as.factor(testdata$class))
  
  #A. Multinomial Logistic regression error rate 
  #library(nnet)
  modA <- multinom(as.factor(class) ~ ., data = traindata)
  y2hatA <- as.numeric(predict(modA,newdata = testdata[,-1], type="class"))
  te1 <- sum(y2hatA != y2_test)/length(y2_test) 

  #B.Linear Discriminant Analysis : 
  #library(MASS)
  modB <- lda(traindata[,2:28], traindata[,1])
  y2hatB <- as.numeric(predict(modB, testdata[,-1])$class)
  te2 <- mean( y2hatB  != y2_test)

  ## C. Naive Bayes (with full X). Testing error 
  #library(e1071)
  modC <- naiveBayes(as.factor(class) ~. , data = traindata)
  y2hatC <- as.numeric(predict(modC, newdata = testdata))
  te3 <- mean( y2hatC != y2_test) 

  #E: a single Tree: 
  #library(rpart)
  modE0 <- rpart(as.factor(class) ~ .,data=traindata, method="class", 
                parms=list(split="gini"))
  opt <- which.min(modE0$cptable[, "xerror"]); 
  cp1 <- modE0$cptable[opt, "CP"];
  modE <- prune(modE0,cp=cp1);
  y2hatE <-  as.numeric(predict(modE, testdata[,-1],type="class"))
  te4 <- mean(y2hatE != y2_test)

  #F: Random Forest: 
  library(randomForest)
  modF <- randomForest(as.factor(class) ~., data=traindata, 
                      importance=TRUE)
  y2hatF = as.numeric(predict(modF, testdata, type='class'))
  te5 <- mean(y2hatF != y2_test)
  
  TEALL = rbind( TEALL, cbind(te1, te2, te3, te4, te5) );
}
dim(TEALL); ### This should be a Bx7 matrices

## You can report the sample mean and sample variances for the models

TEmeans <- apply(TEALL, 2, mean)
TEmeans <- append(TEmeans, te0, 0)
#TEvar <- apply(TEALL, 2, var);
TEmeans <- t(data.frame(TEmeans))
#TEvar
### if you want, you can change the column name of TEALL
colnames1 <- c("GBM", "Multi. Log Reg", "LDA", "Bayes", "Single Tree", "Random Forest");
TEmeans <- as.numeric(TEmeans)
TEmeans

par(mar = c(7,5,4,3))
plot(TEmeans, type = "b",col="red", ylab="Test Error Rate", xlab="", lwd=2, font.lab=2, main="Model Comparision (Mean)",
     cex.axis = 1.5,cex.lab = 1.5,font=2, cex.main=1.5, xaxt = 'n')
axis(1, at = 1:6, labels = colnames1, las = 3)
#par(mar = c(6,5,4,3))
#plot(TEvar, type = "b",col="blue", ylab="Test Error Rate (Var)", xlab="", lwd=2, font.lab=2, main="Model Comparision (Variance)",
 #    cex.axis = 1.5,cex.lab = 1.5,font=2, cex.main=1.5, xaxt = 'n')
#axis(1, at = 1:6, labels = colnames(TEALL), las = 3)

