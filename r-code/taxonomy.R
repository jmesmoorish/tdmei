contracts <- read.csv("selectedAddressesTypes.csv", header = TRUE)

types <- unique(contracts$type)
types

count <- table(contracts$type)
count

hist(contracts$txcoun, ylim=c(0, 250), xlab="Transactions")








