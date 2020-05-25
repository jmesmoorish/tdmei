//const xlsxFile = require('read-excel-file/node')
const fs = require('fs')
const readline = require('readline')
const path = require('path');
const ObjectsToCsv = require('objects-to-csv')
const glob = require("glob")
 
const folder = 'D:/Dropbox/0_isep/TDMEI/collectSmartContractsFromEtherscan/collectedContracts/'
const folder2 = 'D:/Dropbox/0_isep/TDMEI/collectSmartContractsFromEtherscan/other/'
let foundFiles=[]

/*fs.readdir(path, function(err, items) {for (var i=0; i<items.length; i++) {console.log(items[i])}});*/
const getLines = () => {
    glob(folder+'*.sol', function (er, files) {
        console.log('Total files scanned:' +files.length)
        for (let i=0; i<files.length; i++) {
            let fileName = path.basename(files[i]) //console.log(i+' - '+fileName)
            let readInterface = readline.createInterface({
                input: fs.createReadStream(files[i]),
                //output: process.stdout,
                console: false
            });
            readInterface.on('line', function(line) {
                if (line.includes("import")){
                    console.log(fileName)
                    foundFiles.push({contract: fileName});
                    readInterface.pause()
                    readInterface.removeAllListeners()
                    console.log('closed!')

                }
            });
        }
    })
}

getLines()

setTimeout(async () => {
    let csv = {}
    csv = new ObjectsToCsv(foundFiles); await csv.toDisk(folder2+'multiple_files_contracts.csv', { append: false })
    console.log('Total files found:' +foundFiles.length)
},1000)



