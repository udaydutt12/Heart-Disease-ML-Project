#Classification Using Boosting

library (gbm)
myData<-rdata

# Remove 'pnum' from the data as a response variable is derived from it
myData$pnum<-NULL

# Train the Boosting Model
set.seed(777)
train<-sample(297,212,replace=FALSE)
test<-(-train)
test.phd<-myData$phd[test]
boost.myData<-gbm(phd~.,data=myData[train,],
                  distribution="bernoulli",
                  n.trees=5000,shrinkage=0.001,
                  interaction.depth=4)
summary(boost.myData)

# Make a Prediction using the Boosting Model
pred.boost<-predict(boost.myData,newdata=myData[test,],
                    n.trees=5000,type="response")

# Assume threshold cutoff = 0.5
threshold<-0.5
pred.class<-ifelse(pred.boost>threshold,1,0)
table(pred.class,test.phd)

# Using ROC Curve for determining 'threshold'
library(ROCR)
pred_roc <- prediction(pred.boost, test.phd)
perf <- performance(pred_roc,"tpr","fpr")
plot(perf)
plot(perf,colorize=TRUE)
perf_spec <- performance(pred_roc, "sens", "spec")
plot(perf_spec)

# List threshold cutoff values along with fpr and tpr
cutoffs <- data.frame(cut=perf@alpha.values[[1]], fpr=perf@x.values[[1]],
                      tpr=perf@y.values[[1]])
cutoffs <- cutoffs[order(cutoffs$tpr, decreasing=TRUE),]
#head(subset(cutoffs, fpr < 0.2))

# Calculate the best threshold
best_threshold <- function(predict, response) {
  perf <- ROCR::performance(ROCR::prediction(predict, response), "sens", "spec")
  df <- data.frame(cut = perf@alpha.values[[1]], sens = perf@x.values[[1]], 
                   spec = perf@y.values[[1]])
  df[which.max(df$sens + df$spec), "cut"]}
predict<-pred_roc@predictions[[1]]
response<-pred_roc@labels[[1]]
best_cutoff<-best_threshold(predict, response)

# False Positive Rate (fpr) and True Positive Rate(tpr) corresponding to best cutoff.
subset(cutoffs, cut == best_cutoff)

# It appears that the best threshold = 0.5484, after making several runs,
# shrinkage factor of 0.001 was found reasonable.

# Prediction on the test set. 
# With boosting, the number of trees is a tuning parameter that 
# computes the test error as a function of the number of trees.
n.trees=seq(from=100,to=10000,by=100)
predmat=predict(boost.myData,newdata=myData[test,],
                    n.trees=n.trees,type="response")
dim(predmat)
predmat.class<-ifelse(predmat>=best_cutoff,1,0)
cerr<-(predmat.class!=test.phd)
berr<-apply(cerr,2,mean)
plot(n.trees,berr,pch=19,ylab="Mean Classifcation Error", 
     xlab="# Trees",main="Boosting Test Error")
abline(h=min(berr),col="red")
#table(pred.class,test.phd)
#mean(ped.class==test.phd)


# At ntrees = 5000, the Mean Classification Error stabilized (MSE=15%).
# So, we determined that the Best Model has: 
# ntrees = 5000 
# shrinkage factor = 0.001 
# threshold = 0.538

