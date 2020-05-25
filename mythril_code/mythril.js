//const ObjectsToCsv = require('objects-to-csv')
//const xlsxFile = require('read-excel-file/node')
const fs = require('fs')
const readline = require('readline')
const path = require('path');
const glob = require("glob")
const { exec } = require('child_process');
 
const folder = 'D:/Dropbox/0_isep/TDMEI/collectSmartContractsFromEtherscan/test/'
//const folder = '/home/tiago/Desktop/mythril/'
const seconds = process.argv[02]
console.log('Seconds: '+seconds)

const getFiles = () => {
    //glob("**/*.js", options, function (er, files) { // options is optional
    glob(folder+'*.sol', function (er, files) {
        console.log('Total files:' +files.length)
        for (let i=0; i<files.length; i++) {
            let fileName = path.basename(files[i]) //remove path from file name
            let fileName2 = path.basename(files[i], '.sol') // remove extension .sol from file name
            //exec('ls | grep js', (err, stdout, stderr) => {
            let readInterface = readline.createInterface({
              input: fs.createReadStream(files[i]),
              //output: process.stdout,
              console: false
            });
            readInterface.on('line', function(line) {
              if (line.includes("pragma solidity")){
                let version = line.match(/\d.\d.\d+/)
                exec('myth analyze --execution-timeout '+seconds+' --solv '+version+' '+fileName+' > '+fileName2+'.txt', (err, stdout, stderr) => {
                    if (err) {
                      console.error(i+' - Erro: '+err)
                    } else {
                    // the *entire* stdout and stderr (buffered)
                    //console.log(`stdout: ${stdout}`); console.log(`stderr: ${stderr}`);
                    //console.log(i+'- Sucesso: '+fileName)
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

//getFiles()

//setTimeout(async () => {
 //do some code
//},1000)



