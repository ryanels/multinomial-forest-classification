# multinomial-forest-classification
Multinomial forest classification 

This project was completed in Spring 2022 for ISYE 7406 Data Mining and Statistical Learning, a graduate course through Georgia Tech.

Multinomial classification of forest dataset using R. See the PDF report for full analysis and writeup.

Using data from: UCI Machine Learning Repository: Forest Type Mapping Data Set, https://archive.ics.uci.edu/ml/datasets/Forest+type+mapping, Accessed 21 Mar 2022
Dataset has observations of forest "spectral characteristics at visible-to-near infrared wavelengths, using ASTER satellite imagery."

Not accepting push requests

# Abstract
Using satellite imagery, it is informative to be able to predict the forest cover type from spectral characteristics without having to manually label each observation. 

To try and predict “Forest Cover Type” for a multi-class dataset, I built boosting, random forest, LDA, multinomial logistic regression, Naïve Bayes, and single tree models. Using cross-validation for all model types, I found that random forest performed best and had the lowest test error rate. Boosting provided the second-best results. 

# Introduction
For this homework, I am using random forest and boosting methods with a “Forest Cover Type” mapping dataset from UC Irvine (1). Each observation includes multiple spectral features (predictors) and is labeled as a type of forest or non-forest land that needs to be predicted as part of a multi-class classification problem. 

Using training and testing splits with cross-validation, I will find test error rates for random forest and boosting methods and compare them to other baseline classification methods like LDA, Naïve Bayes, Single Tree, and Multinomial Regression.

# Exploratory Data Analysis and Data Sources
The dataset comes from the UC Irvine Machine Learning Repository (1) and includes 523 total observations, each with 28 features. The original data and associated paper (2) from 2012 are by Johnson, et al. 

There is 1 response variable, class, and there are 27 predictor variables. The class variable is categorical with four possible values so this is a multiclass problem without ordinality, where possible classes for different forest cover types are “d, h, s, or o,” which stand for deciduous mixed forest, Hinoki forest, Sugi forest, or other non-forest land, respectively.

As downloaded, the data was pre-split into training and testing datasets, though the training dataset only contained 198 observations while the testing dataset contained 325 observations. Because of the unusual split between training and testing datasets, I decided to merge them and create my own splits as needed. 

 

One thing I noticed while exploring the data is that the classes are unbalanced when training and testing data is combined (as shown below). 

| Forest Type      | Count|
| :---        |     ---: |
| d     | 159       |
| h  | 86        |
| s     | 195       | 
| o     | 83       | 

Classes were reasonably well balanced if the training set was used on its own, however.  Regardless, in order to use the combined data, I oversampled the “h” and “o” classes in order to have similar counts across the four labels. This gave a dataset that was much better balanced. My final dataset had the below class counts.

| Forest Type      | Count|
| :---        |     ---: |
| d     | 159       |
| h  | 172        |
| s     | 195       | 
| o     | 166       | 

# Proposed Methodology
My methodology begins with downloading the data and merging the provided training and testing datasets into one larger dataset. This was done because of the unusual train/test split as noted in the previous section. Next, I had to oversample some classes to ensure my data was reasonably well balanced. For my analysis, when splitting this merged and oversampled data, I split randomly so I had 80% training data and 20% testing data when building my models. 

For boosting, I used cross-validation with 10-fold CV. I built my model with 5000 boosting iterations and selected the number of iterations with the maximum accuracy as my selected model (see Appendix for additional discussion on selected metric). I used that model to predict test dataset classifications and took the class with the highest probability as the predicted class.

For the other models (Multi-class Logistic Regression, LDA, Naïve Bayes, Single Tree, and Random Forest), I used 100 cross-validation iterations and for each iteration I randomly split the data into training and testing datasets. For each iteration, I built each model with the training data and found the error rate for the test data. The overall test error rate for each model was calculated as the average of all 100 individual test error rates. 

Using cross-validation provides a much more robust and accurate overall test error rate since there is no concern that any given random split may have provided an outlier result where the test error rate was unusually high or low. 

# Analysis and Results
For the boosting algorithm (GBM), the accuracy versus number of boosting iterations was plotted. Accuracy improves as boosting iterations are increased before largely leveling off. Using the model with the number of boosting iterations that provided the best accuracy, I predicted the classifications for the test data and found the test error rate. 

For the given dataset, the random forest model provided the smallest testing error. The second-best error rate was the boosting model, followed by Multi-Class Logistic Regression and the remainder of the models as shown in the following table.
 
| Model      | Test Error Rate|
| :---        |     ---: |
| GBM     | 0.0725       |
| Multi-Class Logistic Reg  | 0.1096        |
| LDA     | 0.1184       | 
| Naïve Bayes       | 0.1243       | 
| Single Tree     | 0.1370       | 
| Random Forest      | 0.0709      | 
 
# Conclusion
In conclusion, random forest provided the best model with the lowest test error rate. Boosting was very similar to random forest in providing a small test error rate, but it took the longest to run, so there may be a computational expense that exceeds that of other models. While it performed similarly to random forest, if a large dataset was being analyzed it’s possible that it might be too computationally expensive. As such, it makes sense to use random forest rather than boosting with this data.

Possible future work includes extending this type of analysis to other datasets with additional cover types, or possibly combining all the forest types (deciduous, Hinoki, and Sugi) and predicting a combined forest class against a single non-forest class. This would be a simpler binary response problem where an observation was forest or non-forest. The analysis could also be redone using the provided training and testing datasets as they were downloaded, ignoring the fact that the testing dataset had more observations than the testing set.  

# Lessons I have Learned
Some lessons I have learned are how powerful boosting and random forest can be. I also learned how to perform a multi-class analysis, which extended my knowledge beyond a simple binary response problem. I also learned about the Kappa performance metric (as discussed in the Appendix), though it was unclear if it is beneficial to use it. 

Most importantly, it was reinforced in my mind that having balanced or relatively balanced classes is important when building models to perform classifications. Initially, I didn’t balance my classes after I combined the training and testing datasets. This resulted in models that were less accurate. It was after I realized that the classes were imbalanced that I corrected this problem and redid my models and predictions. 

 
# Appendix
Additional Technical Discussion

Accuracy was used as the metric for the boosting model, although there are other options. 

I also tried to use “Kappa” as the metric for the boosting model, and I ended up with the same index (i.e., the same number of boosting iterations) for the max Kappa value as I did for the maximum Accuracy value. As such, the same model was selected, and my test error rate didn’t change from that presented in the Results section.

However, before I balanced the classes, when I used Kappa, I found a test error rate of 14.29% which was more in-line with Naïve Bayes, Multiclass logistic regression, and single tree models (again, before balancing classes). This was a higher test error rate than found with Accuracy, which points out that at least in some cases, particularly when classes are unbalanced, Kappa and Alpha may return different values and subsequently select different models. 

Ultimately, choosing Accuracy or Kappa as the performance metric didn’t matter since they gave the same result once I balanced the dataset. However, according to some articles (3), using Kappa may introduce problems and should be avoided. For that reason, I was planning to use accuracy as my metric for the boosting algorithm even if the results were different. 

# Bibliography and Credits
1.	UCI Machine Learning Repository: Forest Type Mapping Data Set, https://archive.ics.uci.edu/ml/datasets/Forest+type+mapping, Accessed 21 Mar 2022

2.	Johnson, B., Tateishi, R., Xie, Z., 2012. Using geographically-weighted variables for image classification. Remote Sensing Letters, 3 (6), 491-499.

3.	Delgado R, Tibau X-A (2019) Why Cohen’s Kappa should be avoided as performance measure in classification. PLoS ONE 14(9): e0222916. https://doi.org/10.1371/journal.pone.0222916
