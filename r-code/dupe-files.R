pkg <- c("digest", "stringr", "filesstrings")
new.pkg <- pkg[!(pkg %in% installed.packages())]
if (length(new.pkg)) {install.packages(new.pkg)}
library(digest)
library(stringr)
library(filesstrings)

test_dir= "D:/Dropbox/0_ISEP/TDMEI/collectSmartContractsFromEtherscan/collectedContractsOriginal"
filelist <- dir(test_dir, pattern = ".sol", recursive=TRUE, all.files =TRUE, full.names=TRUE)

md5s <- sapply(filelist,digest,file=TRUE,algo="md5", length = 5000)
duplicate_files <- split(filelist,md5s)

# now let's divide the list into duplicates ( length > 1) and uniques ( length - 1)
z <- duplicate_files
z2 <- sapply(z,function (x){length(x)>1})
z3 <- split(z,z2)
dupes <- z3$"TRUE"

# remove duplicated contracts
for (i in 1:length(dupes)){ 
  for (j in 1:length(dupes[[i]][])){
    if (j > 1){
      file.move(dupes[[i]][j], "D:/Dropbox/0_ISEP/TDMEI/collectSmartContractsFromEtherscan/duplicated_contracts")
    }
  }
}

