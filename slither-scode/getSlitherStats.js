const fs = require('fs')
const path = require('path');
const ObjectsToCsv = require('objects-to-csv')
const glob = require("glob")
//const neatCsv = require('neat-csv')
//const xlsxFile = require('read-excel-file/node')

// /mnt/d/ inicio caminho ubunut // D:/
const folder1 = '/mnt/d/Dropbox/0_ISEP/TDMEI/tdmei/other/slither/'
const folder2 = '/mnt/d/Dropbox/0_ISEP/TDMEI/tdmei/test/'
let stats = [] //stats por vulnerabilidade
let stats2 = [] //stats por contrato
let errors = []
let cleanContracts = []
let total = 0

/*fs.readdir(path, function(err, items) {for (var i=0; i<items.length; i++) {console.log(items[i])}});*/
const getStats = (folder) => { //glob("**/*.js", options, function (er, files) { // options is optional
    glob(folder+'*.json', function (er, files) {
        console.log('Total contracts:' +files.length)
        for (let i=0; i<files.length; i++) {
            let fileName = path.basename(files[i]) //let fileName = path.basename(files[i],'.sol')
            fileName = fileName.split('.').slice(0, -1).join('.') // remover extensao
            let obj = JSON.parse(fs.readFileSync(files[i], 'utf8'));
            //console.log('Object: '+JSON.stringify(obj.results.detectors[0].check, null, '\t'))
            if (obj.error !== null || obj.success === false){
                errors.push(fileName)
            }

            if (obj.success === true && Object.keys(obj.results).length === 0){ //console.log("Success: "+obj.success)
                cleanContracts.push(fileName)
            }
            //let fileLines = fs.readFileSync(files[i]).toString().split("\n") // para criar array de strings
            //if (!fileLines[0].includes("{")){console.log(fileName);}
            //console.log('Issues length: '+obj.issues.length)  
            if (obj.results.detectors !== undefined){
                for (let j=0; j<obj.results.detectors.length; j++) {
                    total++
                    let contractsArray, aux
                    let aux2 = stats.filter(stat => stat.check === obj.results.detectors[j].check)
                    if (aux2.length > 0){ //console.log(j+' - Aux2:' +JSON.stringify(aux2, null, '\t'))
                        aux2[0].count++ //console.log('Count: '+aux2[0].count)
                        aux2[0].contracts.push(fileName) //console.log('Contracts: '+aux2[0].contracts)  
                    }else{
                        contractsArray = []; contractsArray.push(fileName)
                        aux = {check: obj.results.detectors[j].check, count: 1, contracts: contractsArray}
                        stats.push(aux)
                    }
                    aux2 = stats2.filter(stat => stat.contract === fileName)
                    if (aux2.length > 0){ 
                        aux2[0].count++
                        aux2[0].vulns.push(obj.results.detectors[j].check)
                    }else{
                        contractsArray = []; contractsArray.push(obj.results.detectors[j].check)
                        aux = {contract: fileName, count: 1, vulns: contractsArray} 
                        stats2.push(aux)
                    }
                }
            }
        }
    })
}

getStats(folder1)

setTimeout(async () => {
    console.log('Total Vulnerabilities: '+total)
    console.log('Clean: '+cleanContracts.length+' - '+JSON.stringify(cleanContracts, null, '\t')) 
    //console.log('Clean: '+cleanContracts.length+' - '+cleanContracts) 
    console.log('Errors: '+errors.length+' - '+JSON.stringify(errors, null, '\t')) 
    console.log('Stats: '+JSON.stringify(stats, null, '\t'))  
    let csv = new ObjectsToCsv(stats) // so funciona com arrays de objetos
    await csv.toDisk('slitherStats.csv', { append: false}) 
    csv = new ObjectsToCsv(stats2) // so funciona com arrays de objetos
    await csv.toDisk('slitherStats_2.csv', { append: false}) 
},1000)





