# initialise
rm(list=ls())

PR_media <- read.csv("~/Desktop/Amazon-Project/PR.csv")
OB_meida <- read.csv("~/Desktop/Amazon-Project/OB.csv")
# set up working diretory

pacman::p_load(dplyr,rpart,rpart.plot,rattle,caTools,caret,randomForest,openxlsx,e1071,data.table,ggplot2,stats)

#libraries
library(dplyr)
library(randomForest)
library(data.table)
require(ggplot2)
require(stats)

#Data_preparation
PR_media <- read.csv("~/Desktop/Amazon-Project/PR.csv")
OB_media <- read.csv("~/Desktop/Amazon-Project/OB.csv")

set.seed(789)
OB_media_dt <- data.table(OB_media)
OB_media_sample <- OB_media_dt[sample(.N, 30000)]
PR_media_dt <- data.table(PR_media)
PR_media_sample <- PR_media_dt[sample(.N, 30000)]

#Combine_2_Samplesets_together
nd<-rbind(OB_media_sample, PR_media_sample)


##############missing value############

#last_inbound missing rate - 15%
length(nd$last_inbound[which(nd$last_inbound == "")])/length(nd$last_inbound)
#asin_creation_date missing rate - 0%
length(nd$asin_creation_date[which(nd$asin_creation_date == "")])/length(nd$asin_creation_date)
#############feature engineering#############

#nd$last_inbound <- as.Date(nd$last_inbound)
nd$label <- as.factor(nd$label)
nd$procurability <- as.factor(nd$procurability)
nd$policy_name <- as.factor(nd$policy_name)
#Set Missing_Value Of inv_ave As Median 
nd$inv_avg[which(is.na(nd$inv_avg))] <- median(nd$inv_avg, na.rm=TRUE)
nd$is_auto <- as.factor(nd$is_auto)
nd$lifecycle <- as.factor(nd$lifecycle)

#Set Missing_Value Of total_gv As 0 
nd$total_gv[which(is.na(nd$total_gv))] <- 0
#Set Missing_Value Of last_inbound As "2010/1/1"
nd <- nd[which(nd$last_inbound != ""),]

#Set Today_Date AND Differences AS History
td <- as.Date("2017-11-26")
nd$last_inbound[nd$last_inbound==""]<-"2010/1/1"
nd$last_inbound <- as.Date(nd$last_inbound)
inbound_history = as.numeric(td - nd$last_inbound)
nd$asin_creation_date <- as.Date(nd$asin_creation_date)
asin_history = as.numeric(td - nd$asin_creation_date)
#Combine History_Records Into nd
nd <- cbind(nd, asin_history, inbound_history)
#%>%filter(asin_history!="")

################# three variables ################
nd$completepo = as.numeric(nd$completepo)
nd$vendor_num = as.numeric(nd$vendor_num)
nd$total_gv = as.numeric(nd$total_gv)
nd$inv_avg = as.numeric(nd$inv_avg)

ggplot(nd, aes(x = completepo)) +
        geom_histogram(fill = 'yellow', colour = 'black',bins=30) +
        facet_grid(label~., scales = 'free')

ggplot(nd, aes(x = inv_avg)) +
        geom_histogram(fill = 'green', colour = 'black',bins=30) +
        facet_grid(label~., scales = 'free')

ggplot(nd, aes(x = total_gv)) +
        geom_histogram(fill = 'yellow', colour = 'black',bins=30) +
        facet_grid(label~., scales = 'free')

##############Histogram#############
ggplot(nd, aes(x = asin_history)) +
  geom_histogram(fill = 'blue', colour = 'black',bins=30) +
  facet_grid(label~., scales = 'free')

ggplot(nd, aes(x = inbound_history)) +
  geom_histogram(fill = 'red', colour = 'black') +
  facet_grid(label~., scales = 'free')

# ggplot(nd[nd$last_inbound == "",], aes(x = asin_history)) +
#   geom_histogram(fill = 'red', colour = 'black', bins = 30) +
#   facet_grid(label~., scales = 'free')

# correlation just for introduction, no means here!!!!!!!
with(na.omit(nd),cor(total_units,inv_avg))

#hypothesis
with(nd,t.test(inbound_history[label=="PR"],inbound_history[label=="OB"]))

with(nd,t.test(total_gv[label=="PR"],total_gv[label=="OB"]))

with(nd,t.test(completepo[label=="PR"],completepo[label=="OB"]))

with(nd,t.test(vendor_num[label=="PR"],vendor_num[label=="OB"]))

with(nd,t.test(inv_avg[label=="PR"],inv_avg[label=="OB"]))
##############Decision_Tree############
#9_Variables Make Sense
nnd <- nd %>% 
  select (
    ASIN,
    label,
    #lifecycle,
    #procurability,
    inv_avg,
    completepo,
    #is_auto,
    vendor_num,
    last_inbound,
    asin_history,
    inbound_history,
    #fill_rate,
    total_gv
  )
################only six variables
nnd <- nd %>% 
        select (
                ASIN,
                label,
                inv_avg,
                completepo,
                vendor_num,
                asin_history,
                inbound_history,
                total_gv
        )

sample = sample.split(nnd$ASIN, SplitRatio = .75)
train = subset(nnd, sample == TRUE)
test = subset(nnd, sample == FALSE)

fit <- rpart(label ~ 
               #lifecycle+
               #procurability+
               inv_avg+
               completepo+
               #is_auto+
               vendor_num+
               asin_history+
               inbound_history+
               #fill_rate+
               #vltcat+
               total_gv,
               data=train,
               method="class",
               control = rpart.control(maxdepth = 30)
             )
#############only six variables
fit <- rpart(label ~ inv_avg+
                     completepo+
                     vendor_num+
                     asin_history+
                     inbound_history+
                     total_gv,
             data=train,
             method="class",
             control = rpart.control(maxdepth = 30)
)


fancyRpartPlot(fit)
Prediction <- predict(fit, test, type = "class")
table(Prediction, test$label)
confusionMatrix(Prediction, test$label)

#Random_Forest
RandomForest <- randomForest(
  label ~ 
    #lifecycle+
    #procurability+
    inv_avg+
    completepo+
    #is_auto+
    vendor_num+
    asin_history+
    total_gv+
    inbound_history,
  #fill_rate,
  #vlt_cat,
  data=train,
  importance=TRUE, 
  ntree=100)

############# only six variables
RandomForest <- randomForest(
        label ~ inv_avg+
                completepo+
                vendor_num+
                asin_history+
                total_gv+
                inbound_history,
        data=train,
        importance=TRUE, 
        ntree=100)


varImpPlot(RandomForest)

Prediction2 <- predict(RandomForest, test)
table(Prediction2, test$label)
confusionMatrix(Prediction2, test$label)

Prediction22<- predict(RandomForest,train)
table(Prediction22, train$label)
confusionMatrix(Prediction22, train$label)

#############model_resilts##############
submit <- data.frame(ASIN = test$ASIN, total_gv=test$total_gv, inbound_history = test$inbound_history,asin_history=test$asin_history, label = test$label, predict = Prediction2)
write.csv(submit, file = "media_pending_prediction.csv", row.names = FALSE)