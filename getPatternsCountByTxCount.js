const fs = require('fs')
const path = require('path');
const ObjectsToCsv = require('objects-to-csv')
const xlsxFile = require('read-excel-file/node')
var glob = require("glob")
const neatCsv = require('neat-csv')

let accessRest = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let multsig  = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let owner = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let commitReveal = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let guardCheck = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let memoryArray = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let oracle = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let poll = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let pullPayment = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let randomness = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let safemath = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let stateMachine = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let stringEqual = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let tightVar = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}] 
let token = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let autoDep = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let composer = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let factory = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let register = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let relay = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let segregation = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let mortal = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let satellite = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let balanceLimit = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let checks = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let emergency = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let mutex = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let rateLimit = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let secureEther = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let speedBump = [{type:'2thousand', count:0, contracts:[]},{type:'4thousand', count:0, contracts:[]},{type:'6thousand', count:0, contracts:[]},{type:'8thousand', count:0, contracts:[]},{type:'10thousand', count:0, contracts:[]}]
let lapses=[]

const folder_1 = 'D:/Dropbox/0_isep/TDMEI/tdmei/collectedContracts/'
const folder_2 = 'D:/Dropbox/0_isep/TDMEI/tdmei/code/pattern_samples/'
const folder_test = 'D:/Dropbox/0_isep/TDMEI/tdmei/test/'
const folder_sec = 'D:/Dropbox/0_isep/TDMEI/tdmei/code/pattern_samples/security/'
const folder_auth = 'D:/Dropbox/0_isep/TDMEI/tdmei/code/pattern_samples/authorization/'
const folder_control = 'D:/Dropbox/0_isep/TDMEI/tdmei/code/pattern_samples/control/'
const folder_maint = 'D:/Dropbox/0_isep/TDMEI/tdmei/code/pattern_samples/maintenance/'
let list = []

fs.readFile('selectedAddressesTypes.csv', async (err, data) => {
    if (err) {
      console.error('Error: '+err)
      return
    }
    //console.log(await neatCsv(data))
    list = await neatCsv(data)
})

const getTxCountById = (id) => {
    for (let i=0; i<list.length; i++) {
        if (list[i].index === id){ 
            return list[i].txcount 
        }
    }
}

const getTxCountPos = (txcount) => {

    if (txcount<2001) {return 0}
    if (txcount>2000 && txcount<4001) {return 1}
    if (txcount>4000 && txcount<6001) {return 2}
    if (txcount>6000 && txcount<8001) {return 3}
    if (txcount>8000 && txcount<10001) {return 4}
}

/*fs.readdir(path, function(err, items) {for (var i=0; i<items.length; i++) {console.log(items[i])}});*/
const getPatterns = (folder) => {
    //glob("**/*.js", options, function (er, files) { // options is optional
    glob(folder+'*.xlsx', function (er, files) {
        // files is an array of filenames.
        // If the `nonull` option is set, and nothing
        // was found, then files is ["**/*.js"]
        // er is an error object or null.
        console.log('Total files:' +files.length)
        for (let i=0; i<files.length; i++) {
            let aux = []
            let txcount = ''
            let pos = -1
            let fileName = path.basename(files[i]) //console.log(i+' - '+fileName)
            fileName = fileName.split('.').slice(0, -1).join('.') // remover extensao
            aux = fileName.split('_')
            txcount = getTxCountById(aux[aux.length-1])
            pos =  getTxCountPos(txcount)
                xlsxFile(files[i]).then((rows) => { //xlsxFile('./Data.xlsx').then((rows) => {
                    //console.log(rows); //console.table(rows);
                    for (let j=1; j<rows.length; j++) {
                        //for (k in rows[j]){console.dir(rows[j][k])}  
                        switch (rows[j][0].toLowerCase()){
                            case 'access restriction': accessRest[pos].count++; accessRest[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'multiple authorization': multsig[pos].count++; multsig[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'ownership': owner[pos].count++; owner[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            //
                            case 'commit and reveal': commitReveal[pos].count++; commitReveal[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'guard check': guardCheck[pos].count++; guardCheck[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'memory array building': memoryArray[pos].count++; memoryArray[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'oracle': oracle[pos].count++; oracle[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'poll': poll[pos].count++; poll[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'pull payment': pullPayment[pos].count++; pullPayment[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'randomness': randomness[pos].count++; randomness[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'safemath': safemath[pos].count++; safemath[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'state machine': stateMachine[pos].count++; stateMachine[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'string equality comparison': stringEqual[pos].count++; stringEqual[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'tight variable packing': tightVar[pos].count++; tightVar[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'token': token[pos].count++; token[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            //
                            case 'automatic deprecation': autoDep[pos].count++; autoDep[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'contract composer': composer[pos].count++; composer[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'contract factory': factory[pos].count++; factory[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'contract register': register[pos].count++; register[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'contract relay': relay[pos].count++; relay[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'data segregation': segregation[pos].count++; segregation[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'mortal': mortal[pos].count++; mortal[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'satellite': satellite[pos].count++; satellite[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            //
                            case 'balance limit': balanceLimit[pos].count++; balanceLimit[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'checks-effects-interaction': checks[pos].count++; checks[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'emergency stop': emergency[pos].count++; emergency[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'mutex': mutex[pos].count++; mutex[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'rate limit': rateLimit[pos].count++; rateLimit[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'secure ether transfer': secureEther[pos].count++; secureEther[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            case 'speed bump': speedBump[pos].count++; speedBump[pos].contracts.push({contract: fileName, line: rows[j][1]}); break
                            default: lapses.push({contract: fileName, pattern: rows[j][0], line: rows[j][1]}); break
                        }
                    }
            })
        }
    })
}

function onlyUnique(value, index, self){ //devolve valores unicos
    return self.indexOf(value) === index;
}
//let unique = names.filter(onlyUnique);

function getUniques(arr){
    let newArr = []
    for (let i=0; i<arr.length; i++) {
        newArr.push(arr[i].contract)
    }
    return newArr.filter(onlyUnique);
}

setTimeout(() => {
    console.log('List size: '+list.length) 
    //console.log('List[0]: '+list[0].name) 
    getPatterns(folder_1)
},1000)

setTimeout(async () => {
    let csv = {}
    //Authorization
    csv = new ObjectsToCsv(accessRest); await csv.toDisk(folder_auth+'accessRestriction_3.csv', { append: false })
    csv = new ObjectsToCsv(multsig); await csv.toDisk(folder_auth+'multipleAuthorization_3.csv', { append: false })
    csv = new ObjectsToCsv(owner); await csv.toDisk(folder_auth+'ownership_3.csv', { append: false })
    //Control
    csv = new ObjectsToCsv(commitReveal); await csv.toDisk(folder_control+'commitReveal_3.csv', { append: false })
    csv = new ObjectsToCsv(guardCheck); await csv.toDisk(folder_control+'guardCheck_3.csv', { append: false })
    csv = new ObjectsToCsv(memoryArray); await csv.toDisk(folder_control+'memoryArrayBuilding_3.csv', { append: false })
    csv = new ObjectsToCsv(oracle); await csv.toDisk(folder_control+'oracle_3.csv', { append: false })
    csv = new ObjectsToCsv(poll); await csv.toDisk(folder_control+'poll_3.csv', { append: false })
    csv = new ObjectsToCsv(pullPayment); await csv.toDisk(folder_control+'pullPayment_3.csv', { append: false })
    csv = new ObjectsToCsv(randomness); await csv.toDisk(folder_control+'randomness_3.csv', { append: false })
    csv = new ObjectsToCsv(safemath); await csv.toDisk(folder_control+'safemath_3.csv', { append: false })
    csv = new ObjectsToCsv(stateMachine); await csv.toDisk(folder_control+'stateMachine_3.csv', { append: false })
    csv = new ObjectsToCsv(stringEqual); await csv.toDisk(folder_control+'stringEqualityComparison_3.csv', { append: false })
    csv = new ObjectsToCsv(tightVar); await csv.toDisk(folder_control+'tightVariablePacking_3.csv', { append: false })
    csv = new ObjectsToCsv(token); await csv.toDisk(folder_control+'token_2.csv', { append: false })
    //Maintenance
    csv = new ObjectsToCsv(autoDep); await csv.toDisk(folder_maint+'automaticDeprecatio_3.csv', { append: false })
    csv = new ObjectsToCsv(composer); await csv.toDisk(folder_maint+'contractComposer_3.csv', { append: false })
    csv = new ObjectsToCsv(factory); await csv.toDisk(folder_maint+'contractFactory_3.csv', { append: false })
    csv = new ObjectsToCsv(register); await csv.toDisk(folder_maint+'contractRegister_3.csv', { append: false })
    csv = new ObjectsToCsv(relay); await csv.toDisk(folder_maint+'contractRelay_3.csv', { append: false })
    csv = new ObjectsToCsv(segregation); await csv.toDisk(folder_maint+'dataSegregation_3.csv', { append: false })
    csv = new ObjectsToCsv(mortal); await csv.toDisk(folder_maint+'mortal_3.csv', { append: false })
    csv = new ObjectsToCsv(satellite); await csv.toDisk(folder_maint+'satellite_3.csv', { append: false })
    //Security
    csv = new ObjectsToCsv(balanceLimit); await csv.toDisk(folder_sec+'balanceLimit_3.csv', { append: false })
    csv = new ObjectsToCsv(checks); await csv.toDisk(folder_sec+'checks-effects-interaction_3.csv', { append: false })
    csv = new ObjectsToCsv(emergency); await csv.toDisk(folder_sec+'emergencyStop_3.csv', { append: false })
    csv = new ObjectsToCsv(mutex); await csv.toDisk(folder_sec+'mutex_3.csv', { append: false })
    csv = new ObjectsToCsv(rateLimit); await csv.toDisk(folder_sec+'rateLimit_3.csv', { append: false })
    csv = new ObjectsToCsv(secureEther); await csv.toDisk(folder_sec+'secureEtherTransfer_3.csv', { append: false })
    csv = new ObjectsToCsv(speedBump); await csv.toDisk(folder_sec+'speedBump_3.csv', { append: false })
    //lapses
    console.log("Lapses: "+lapses.length); csv = new ObjectsToCsv(lapses); await csv.toDisk(folder_2+'lapses.csv', { append: false })
},2000)



