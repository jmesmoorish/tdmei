setwd("D:/Dropbox/0_ISEP/TDMEI/tdmei/code/r_code")
getwd()

pkg <- c("readtext", "quanteda", "openxlsx")

new.pkg <- pkg[!(pkg %in% installed.packages())]

if (length(new.pkg)) {
  install.packages(new.pkg)
}

#install.packages("openxlsx")

suppressPackageStartupMessages(library(quanteda))
library(readtext)
library(openxlsx)

#loading dos ficheiros com o package readtext
folder <- "D:/Dropbox/0_ISEP/TDMEI/tdmei/collectedContracts"  
data <- readtext(paste0(folder, "/*.sol"))
data[1,1]
data[1,2]

docs <- corpus(data) 
docs[1] # aceder ao nome do ficheiro
docs[[1]] # aceder ao codigo do ficheiro. igual a: texts(docs)[1]
summary(docs) 
writeLines(as.character(docs[1]))

#tokens
#tokens(docs[1], remove_numbers = FALSE,  remove_punct = TRUE, remove_separators = FALSE)
#tokens = tokens(docs[1]) #default por palavra. what = "word"
#tokens[1]
#tokens(docs[1], what = "sentence") #separada por por: . ! ? ...
#tokens(docs[1], what = "character")

#kwic(docs, "token", 4) #quanteda function: Search for words with context: 4 words on each side of the keyword

#Build a Document-Feature Matrix (DFM)
solidityWords = c("contract", "function", "library", "returns", "return", "address", "pragma", "pure", "public", "view", "solidity",
                  "require", "+", "=", "<", ">", "uint", "uint256", "uint8", "internal", "external", "payable", "bool", "memory", "bytes", "event", 
                  "modifier", "for", "to", "_to", "from", "_from", "emit", "using", "constructor", "mapping", "is", "msg.sender", "|", "string",
                  "this", "true", "false", "if", "else", "revert", "indexed")

docs_dfm <- dfm(docs, tolower = TRUE, stem = FALSE, remove = solidityWords, remove_punct = TRUE, remove_numbers = TRUE)
docs_dfm

#Dicionario para procurar os padroes por ficheiro/contrato
myDict <- dictionary(list(acessRestriction = c("access restriction", "restriction access", "embedded permission", "time constraint"),
                          ownership = c("ownership", "authorization", "owned", "ownable"), 
                          multisig = c("multiple authorization", "multi-signature"),
                          pullPayment = c("pull payment", "pull over push", "withdrawal contract"),
                          stateMachine = c("state machine"),
                          commit = c("commit and reveal", "encrypting on-chain data", "hash secrett"),
                          oracle = c("oracle", "oraclize", "chainlink"),
                          token = c("token", "tokenisation"),
                          randomness = c("randomness", "random"),
                          poll = c("poll"),
                          math = c("safemath", "math"),
                          guardCheck = c("guard check"),
                          string = c("string equality comparison"),
                          variable = c("tight variable packing"),
                          memory = c("memory array building"),
                          mortal = c("mortal", "suicidal", "termination"),
                          automatic = c("automatic peprecation"),
                          data = c("data contract", "contract data", "eternal storage"),
                          satellite = c("satellite", "contract decorator"),
                          register = c("contract register", "contract registry"),
                          relay = c("contract relay", "contract observer", "proxy", "proxy delegate"),
                          factory = c("factory contract", "contract factory"),
                          composer = c("contract composer", "composer"),
                          checks = c("checks-effects-interaction"),
                          emergency = c("emergency stop", "circuit breaker", "pausable"),
                          speedBump = c("speed bump"),
                          rateLimit = c("rate limit"),
                          mutex = c("mutex", "reentrancy guard", "noReentrancy"),
                          balanceLimit = c("balance limit"),
                          secureTransf = c("secure ether transfer")
                          ))
myDict

#spills_DFM <- dfm(docs, dictionary = myDict) #quanteda function: aplicado diretamente no array corpus puro sem limpezas
spills_DFM <- dfm(docs_dfm, dictionary = myDict) #quanteda function: aplicada na dfm ja com limpezas
spills_DFM

write.xlsx(spills_DFM, "found_patterns.xlsx")





