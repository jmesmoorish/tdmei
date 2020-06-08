const fs = require('fs')
const path = require('path');
const ObjectsToCsv = require('objects-to-csv')
const glob = require("glob")

const folder1 = '/mnt/d/Dropbox/0_ISEP/TDMEI/tdmei/other/mythril/'
const folder2 = 'D:/Dropbox/0_ISEP/TDMEI/tdmei/test/'
let stats = [] //stats by vulnerability
let stats2 = [] //stats by contract
let errors = []
let cleanContracts = []
let total = 0

const getStats = (folder) => { 
    glob(folder+'*.json', function (er, files) {
        console.log('Total contracts:' +files.length)
        for (let i=0; i<files.length; i++) {
            let fileName = path.basename(files[i])
            fileName = fileName.split('.').slice(0, -1).join('.')
            let obj = JSON.parse(fs.readFileSync(files[i], 'utf8'));
            
            if (obj.error !== null || obj.success === false){
                errors.push(fileName)
            }

            if (obj.success === true && obj.issues.length === 0){ 
                cleanContracts.push(fileName)
            }
     
            for (let j=0; j<obj.issues.length; j++) {
                total++
                let contractsArray, aux
                let aux2 = stats.filter(stat => stat.swcId === obj.issues[j]['swc-id'])
                if (aux2.length > 0){
                    aux2[0].count++ 
                    aux2[0].contracts.push(fileName) 
                }else{
                    contractsArray = []; contractsArray.push(fileName)
                    aux = {swcId: obj.issues[j]['swc-id'], title:obj.issues[j].title, count: 1, contracts: contractsArray}
                    stats.push(aux)
                }

                aux2 = stats2.filter(stat => stat.contract === fileName)
                
                if (aux2.length > 0){ 
                    aux2[0].count++
                    aux2[0].vulns.push(obj.issues[j]['swc-id'])
                }else{
                    contractsArray = []; contractsArray.push(obj.issues[j]['swc-id'])
                    aux = {contract: fileName, count: 1, vulns: contractsArray} 
                    stats2.push(aux)
                }
            }
        }
    })
}

getStats(folder1)

setTimeout(async () => {
    console.log('Total Vulnerabilities: '+total)
    console.log('Clean: '+cleanContracts.length+' - '+JSON.stringify(cleanContracts, null, '\t')) 
    console.log('Errors: '+errors.length+' - '+JSON.stringify(errors, null, '\t')) 
    console.log('Stats: '+JSON.stringify(stats, null, '\t'))  
    let csv = new ObjectsToCsv(stats) 
    await csv.toDisk('mythrilStats.csv', { append: false}) 
    csv = new ObjectsToCsv(stats2) 
    await csv.toDisk('mythrilStats_2.csv', { append: false}) 
},1000)





