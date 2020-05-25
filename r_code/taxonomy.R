setwd("D:/Dropbox/0_ISEP/TDMEI/tdmei/code/r_code")
getwd()

#pkg <- c("readtext", "quanteda", "openxlsx")

#new.pkg <- pkg[!(pkg %in% installed.packages())]

#if (length(new.pkg)) {
#  install.packages(new.pkg)
#

#install.packages("openxlsx")

#contracts <- read.csv("selectedAddressesTypesWithoutDuplicated.csv", header = TRUE)

contracts <- read.csv("selectedAddressesTypes.csv", header = TRUE)

types <- unique(contracts$type)
types

count <- table(contracts$type)
count

hist(contracts$txcoun, ylim=c(0, 250), xlab="Transactions")

#contracts <- contracts[order(contracts[, "name"]), , drop = FALSE]

#contracts <- contracts[order(contracts[, "txcount"]), , drop = FALSE]

#write.csv(contracts,'selectedAddressesTypesWithoutDuplicated_v2.csv', row.names = FALSE)







