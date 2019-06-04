# initialise
rm(list=ls())

# set up working diretory
setwd("C:/Users/maruizhu/Desktop/ruizhu学习材料/OB")

pacman::p_load(dplyr,rpart,rpart.plot,rattle,caTools,caret,randomForest,openxlsx,e1071,data.table,ggplot2,stats)

#libraries
# library(dplyr)
# library(rpart)
# library(rpart.plot)
# library(rattle)
# #library(RColorBrewer)
# require(caTools)
# library(caret)
# library(randomForest)
# library(openxlsx)
# library(e1071)
# library(data.table)
# require(ggplot2)
# require(stats)

PR_media <- read.csv("/Users/maruizhu/Desktop/OB/PR.csv", header = TRUE, stringsAsFactors = FALSE, 
                     row.names=NULL)
OB_media <- read.csv("/Users/maruizhu/Desktop/OB/OB.csv", header = TRUE, stringsAsFactors = FALSE, 
                     row.names=NULL)

set.seed(789)
OB_dt <- data.table(OB)
OB_sample <- OB_dt[sample(.N, 30000)]
PR_dt <- data.table(PR)
PR_sample <- PR_dt[sample(.N, 30000)]

##############################################
nd<-rbind(OB_sample, PR_sample)


##############missing value##################
##########last_inbound missing rate - 15.4%
length(nd$last_inbound[which(nd$last_inbound == "")])/length(nd$last_inbound)
#asin_creation_date missing rate - 0%
length(nd$asin_creation_date[which(nd$asin_creation_date == "")])/length(nd$asin_creation_date)

##############feature engineering#############

#asin history
nd$asin_creation_date <- as.Date(nd$asin_creation_date, format = "%m/%d/%Y")
#nd$last_inbound_modified <- as.Date(nd$last_inbound_modified, format = "%m/%d/%Y")
#inbound_history_1 = as.numeric(td - nd$last_inbound_modified)
#nd$last_inbound[which(nd$last_inbound == "")] <- as.character("2010-01-01")
#nd <- nd[which(nd$last_inbound != ""),]
#nd$last_inbound <- as.Date(nd$last_inbound)
#td <- as.Date("2017-08-21")
nd$label <- as.factor(nd$label)
nd$procurability <- as.factor(nd$procurability)
nd$policy_name <- as.factor(nd$policy_name)
nd$inv_avg[which(is.na(nd$inv_avg))] <- median(nd$inv_avg, na.rm=TRUE)
nd$is_auto <- as.factor(nd$is_auto)
nd$lifecycle <- as.factor(nd$lifecycle)

################################################
#MISSING_VALUE_METHOD
nd$total_gv[which(is.na(nd$total_gv))] <- 0
nd <- nd[which(nd$last_inbound != ""),]

td <- as.Date("2017-11-26")
nd$last_inbound <- as.Date(nd$last_inbound, format = "%m/%d/%Y")
inbound_history = as.numeric(td - nd$last_inbound)

nd$asin_creation_date <- as.Date(nd$asin_creation_date, format = "%m/%d/%Y")
asin_history = as.numeric(td - nd$asin_creation_date)

nd <- cbind(nd, asin_history, inbound_history)
#%>%filter(asin_history!="")

################################################
# ggplot(nd, aes(x = asin_history)) +
#   geom_histogram(fill = 'red', colour = 'black',bins=60) +
#   facet_grid(label~., scales = 'free')
# 
# ggplot(nd, aes(x = inbound_history)) +
#   geom_histogram(fill = 'red', colour = 'black') +
#   facet_grid(label~., scales = 'free')
# 
# ggplot(nd[nd$last_inbound == "",], aes(x = asin_history)) +
#   geom_histogram(fill = 'red', colour = 'black', bins = 60) +
#   facet_grid(label~., scales = 'free')