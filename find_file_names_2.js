//const fs = require('fs')
var path = require('path');
const ObjectsToCsv = require('objects-to-csv')
const xlsxFile = require('read-excel-file/node')
var glob = require("glob")

const folder1 = 'D:/Dropbox/0_isep/TDMEI/tdmei/other/slither_modified/'
const folder2 = 'D:/Dropbox/0_isep/TDMEI/tdmei/other/mythril_modified/'
 
let names = []

/*fs.readdir(path, function(err, items) {for (var i=0; i<items.length; i++) {console.log(items[i])}});*/
const getPatterns = (folder) => {
    //glob("**/*.js", options, function (er, files) { // options is optional
    glob(folder+'*', function (er, files) {
        console.log('Total files:' +files.length)
        for (let i=0; i<files.length; i++) {
            //let fileName = path.basename(files[i],'.sol')
                let fileName = path.basename(files[i])
                fileName = fileName.split('.').slice(0, -1).join('.') // remover extensao
                names.push(fileName)
                //console.log(fileName)
            }
    })
}

getPatterns(folder1)
getPatterns(folder2)

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

setTimeout(() => {
    //var unique = names.filter(onlyUnique);
    var unique = foo(names)
    //console.log(unique.length)
    //console.log(unique[0][0])
    //console.log(unique[1][0])
    for (let i=0; i<unique[0].length; i++) {
        if (unique[1][i] < 2){
            console.log(unique[0][i]) 
        }
    }   
},1000)





