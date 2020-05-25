pkg <- c("digest", "stringr", "filesstrings")

new.pkg <- pkg[!(pkg %in% installed.packages())]

if (length(new.pkg)) {
  install.packages(new.pkg)
}

library(digest)
library(stringr)
library(filesstrings)

test_dir= "D:/Dropbox/0_ISEP/TDMEI/collectSmartContractsFromEtherscan/collectedContractsOriginal"
filelist <- dir(test_dir, pattern = ".sol", recursive=TRUE, all.files =TRUE, full.names=TRUE)
filelist

md5s<-sapply(filelist,digest,file=TRUE,algo="md5", length = 5000)
duplicate_files = split(filelist,md5s)

# now let's divide the list into duplicates ( length > 1) and uniques ( length - 1)
z = duplicate_files
z
z2 = sapply(z,function (x){length(x)>1})
z2
z3 = split(z,z2)
z3
head(z3$"TRUE")

length(z3$"FALSE")
length(z3$"TRUE")
lengths(z3$"TRUE")
dupes = z3$"TRUE"
dupes
length(dupes)

dupes[[1]][1]
dupes[[1]][2]
dupes[[26]][]

for (i in 1:length(dupes)){ 
  for (j in 1:length(dupes[[i]][])){
    if (j > 1){
      file.move(dupes[[i]][j], "D:/Dropbox/0_ISEP/TDMEI/collectSmartContractsFromEtherscan/duplicated_contracts")
    }
    #print(j)
  }
}

# copy file
#file.copy("source_file.txt", "destination_folder")

# delete file
#file.remove("some_other_file.csv")

#library(stringr)
#library(filesstrings)
#file.move("C:/path/to/file/some_file.txt", "C:/some/other/path") #library(filesstrings) and library(stringr)
