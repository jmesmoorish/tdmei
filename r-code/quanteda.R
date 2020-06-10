pkg <- c("readtext", "quanteda", "openxlsx")
new.pkg <- pkg[!(pkg %in% installed.packages())]
if (length(new.pkg)) {install.packages(new.pkg)}

#install.packages("openxlsx")
suppressPackageStartupMessages(library(quanteda))
library(readtext)
library(openxlsx)

#loading contracts
folder <- "D:/Dropbox/0_ISEP/TDMEI/tdmei/collectedContracts"  
data <- readtext(paste0(folder, "/*.sol"))

#Create corpus
docs <- corpus(data) 
summary(docs) 
writeLines(as.character(docs[1]))

#remove solidty words
solidityWords = c("contract", "function", "library", "returns", "return", "address", "pragma", "pure", "public", "view", "solidity", 
"require", "+", "=", "<", ">", "uint", "uint256", "uint8", "internal", "external", "payable", "bool", "memory", "bytes", "event", 
"modifier", "for", "to", "_to", "from", "_from", "emit", "using", "constructor", "mapping", "is", "msg.sender", "|", "string",
"this", "true", "false", "if", "else", "revert", "indexed")

#Build a Document-Feature Matrix (DFM)
docs_dfm <- dfm(docs, tolower = TRUE, stem = FALSE, remove = solidityWords, remove_punct = TRUE, remove_numbers = TRUE)

#Create dictionary to search for patterns by file / contract
myDict <- dictionary(list(acessRestriction = c("access restriction", "restriction access", "embedded permission", "time constraint"),
ownership = c("ownership", "authorization"), multisig = c("multiple authorization", "multi-signature"),
pullPayment = c("pull payment", "pull over push", "withdrawal contract"), stateMachine = c("state machine"),
commit = c("commit and reveal", "encrypting on-chain data", "hash secrett"), oracle = c("oracle"),
token = c("token", "tokenisation"), randomness = c("randomness"), poll = c("poll"), math = c("safemath", "math"),
guardCheck = c("guard check"), string = c("string equality comparison"),
variable = c("tight variable packing", "variables packing"),memory = c("memory array building"),
mortal = c("mortal", "termination"), automatic = c("automatic deprecation"),
data = c("data segregation", "data contract", "eternal storage"), satellite = c("satellite", "contract decorator"),
register = c("contract register", "contract registry"), relay = c("contract relay", "contract observer", "proxy", "proxy delegate"),
factory = c("factory contract", "contract factory"),composer = c("contract composer"),
checks = c("checks-effects-interaction"), emergency = c("emergency stop", "circuit breaker", "pausable"),
speedBump = c("speed bump"), rateLimit = c("rate limit"), mutex = c("mutex", "reentrancy guard"),
balanceLimit = c("balance limit"), secureTransf = c("secure ether transfer") ))

#Look for design patterns
spills_DFM <- dfm(docs_dfm, dictionary = myDict) 

#Save results
write.xlsx(spills_DFM, "found_patterns.xlsx")