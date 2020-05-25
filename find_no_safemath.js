const fs = require('fs')
var path = require('path');
const neatCsv = require('neat-csv')
const ObjectsToCsv = require('objects-to-csv')
//const xlsxFile = require('read-excel-file/node')
var glob = require("glob")

const folder1 = 'D:/Dropbox/0_ISEP/TDMEI/tdmei/collectedContracts/'
const folder2 = 'D:/Dropbox/0_ISEP/TDMEI/tdmei/code/pattern_samples/control/'
let safeMathContracts = []
let names = []

const getSafemath = async () => {

    fs.readFile(folder2+'safemath.csv', async (err, data) => {
        if (err) {
        console.error('Error: '+err)
        return
        }
        //console.log(await neatCsv(data))
        safeMathContracts = await neatCsv(data)
        console.log('Total safeMathContracts:' +safeMathContracts.length)
    })


    setTimeout(() => {
        for (let i = 0; i<safeMathContracts.length; i++) {
            let fileName = safeMathContracts[i].contract.split('.').slice(0, -1).join('.') // remover extensao
            names.push(fileName)
        }
        //console.log('Total names:' +names.length) 
    },1000)
}
 


/*fs.readdir(path, function(err, items) {for (var i=0; i<items.length; i++) {console.log(items[i])}});*/
const getPatterns = (folder) => {
    //glob("**/*.js", options, function (er, files) { // options is optional
    glob(folder+'*.sol', function (er, files) {
        console.log('Total contracts:' +files.length)
        for (let i=0; i<files.length; i++) {
            //let fileName = path.basename(files[i],'.sol')
                let fileName = path.basename(files[i])
                fileName = fileName.split('.').slice(0, -1).join('.') // remover extensao
                names.push(fileName)
                //console.log(fileName)
            }
    })
}

getSafemath()
getPatterns(folder1)
//getPatterns(folder2)

function onlyUnique(value, index, self){ //devolve valores unicos
    return self.indexOf(value) === index;
}

function foo(arr) { //conta repeticoes de cada item em um array
    var a = [], b = [], prev;

    arr.sort();
    for ( var i = 0; i < arr.length; i++ ) {
        if ( arr[i] !== prev ) {
            a.push(arr[i]);
            b.push(1);
        } else {
            b[b.length-1]++;
        }
        prev = arr[i];
    }

    return [a, b];
}

setTimeout(async () => {
    //var unique = names.filter(onlyUnique);
    console.log('Total names:' +names.length) 
    let unique = foo(names)
    let result = []
    let obj = {}
    //console.log(unique.length)
    //console.log(unique[0][0])
    //console.log(unique[1][0])
    for (let i=0; i<unique[0].length; i++) {
        if (unique[1][i] < 2){
            //console.log(unique[0][i]) 
            obj = {contract: unique[0][i]}
            result.push(obj)
        }
    }
    console.log('Total noSafemath:' +result.length)  
    let csv = new ObjectsToCsv(result) // so funciona com arrays de objetos
    await csv.toDisk('noSafemathContracts.csv', { append: false}) 
},1000)





