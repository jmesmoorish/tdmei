const fs = require('fs')
const readline = require('readline')
const path = require('path');
const glob = require("glob")
const { exec } = require('child_process');
const folder = 'D:/Dropbox/0_isep/TDMEI/collectSmartContractsFromEtherscan/test/'
const seconds = process.argv[02]
console.log('Seconds: '+seconds)

const getFiles = () => {
    glob(folder+'*.sol', function (er, files) {
        console.log('Total files:' +files.length)
        for (let i=0; i<files.length; i++) {
            let fileName = path.basename(files[i]) 
            let fileName2 = path.basename(files[i], '.sol') 
            let readInterface = readline.createInterface({
              input: fs.createReadStream(files[i]),
              console: false
            });
            readInterface.on('line', function(line) {
              if (line.includes("pragma solidity")){
                let version = line.match(/\d.\d.\d+/)
                exec('myth analyze --execution-timeout '+seconds+' --solv '+version+' '+fileName+' > '+fileName2+'.txt', (err, stdout, stderr) => {
                    if (err) {
                      console.error(i+' - Erro: '+err)
                    } else {
                    console.log(i+' - '+fileName2+' - '+version)
                    }
                  });
                  readInterface.close()
                  readInterface.removeAllListeners()
              }
            });
        }
    })
}

getFiles()




