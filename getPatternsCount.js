var path = require('path');
const ObjectsToCsv = require('objects-to-csv')
const xlsxFile = require('read-excel-file/node')
var glob = require("glob")
const folder = 'D:/Dropbox/0_isep/TDMEI/tdmei/collectedContracts/'
const folder_2 = 'D:/Dropbox/0_isep/TDMEI/tdmei/code/pattern_samples/'
const folder_sec = 'D:/Dropbox/0_isep/TDMEI/tdmei/code/pattern_samples/security/'
const folder_auth = 'D:/Dropbox/0_isep/TDMEI/tdmei/code/pattern_samples/authorization/'
const folder_control = 'D:/Dropbox/0_isep/TDMEI/tdmei/code/pattern_samples/control/'
const folder_maint = 'D:/Dropbox/0_isep/TDMEI/tdmei/code/pattern_samples/maintenance/'
let accessRest=[]; multsig = []; owner=[] 
let commitReveal=[]; guardCheck=[]; memoryArray=[]; oracle=[]; poll=[]; pullPayment=[]; randomness=[]; safemath=[]; stateMachine=[]; stringEqual=[]; tightVar=[]; token = []
let autoDep=[]; composer=[]; factory=[]; register=[]; relay=[]; segregation=[]; mortal=[]; satellite = []
let balanceLimit=[]; checks=[]; emergency=[]; mutex=[]; rateLimit=[]; secureEther=[]; speedBump = []
let lapses=[]
 
const getPatterns = () => {
    glob(folder+'*.xlsx', function (er, files) {
        console.log('Total files:' +files.length)
        for (let i=0; i<files.length; i++) {
            let fileName = path.basename(files[i]) 
                xlsxFile(files[i]).then((rows) => { 
                    for (let j=1; j<rows.length; j++) {
                        switch (rows[j][0].toLowerCase()){
                            // Authorization patterns
                            case 'access restriction': accessRest.push({contract: fileName, line: rows[j][1]}); break
                            case 'multiple authorization': multsig.push({contract: fileName, line: rows[j][1]}); break
                            case 'ownership': owner.push({contract: fileName, line: rows[j][1]}); break
                            // Control patterns
                            case 'commit and reveal': commitReveal.push({contract: fileName, line: rows[j][1]}); break
                            case 'guard check': guardCheck.push({contract: fileName, line: rows[j][1]}); break
                            case 'memory array building': memoryArray.push({contract: fileName, line: rows[j][1]}); break
                            case 'oracle': oracle.push({contract: fileName, line: rows[j][1]}); break
                            case 'poll': poll.push({contract: fileName, line: rows[j][1]}); break
                            case 'pull payment': pullPayment.push({contract: fileName, line: rows[j][1]}); break
                            case 'randomness': randomness.push({contract: fileName, line: rows[j][1]}); break
                            case 'safemath': safemath.push({contract: fileName, line: rows[j][1]}); break
                            case 'state machine': stateMachine.push({contract: fileName, line: rows[j][1]}); break
                            case 'string equality comparison': stringEqual.push({contract: fileName, line: rows[j][1]}); break
                            case 'tight variable packing': tightVar.push({contract: fileName, line: rows[j][1]}); break
                            case 'token': token.push({contract: fileName, line: rows[j][1]}); break
                            // Maintenance patterns
                            case 'automatic deprecation': autoDep.push({contract: fileName, line: rows[j][1]}); break
                            case 'contract composer': composer.push({contract: fileName, line: rows[j][1]}); break
                            case 'contract factory': factory.push({contract: fileName, line: rows[j][1]}); break
                            case 'contract register': register.push({contract: fileName, line: rows[j][1]}); break
                            case 'contract relay': relay.push({contract: fileName, line: rows[j][1]}); break
                            case 'data segregation': segregation.push({contract: fileName, line: rows[j][1]}); break
                            case 'mortal': mortal.push({contract: fileName, line: rows[j][1]}); break
                            case 'satellite': satellite.push({contract: fileName, line: rows[j][1]}); break
                            // Security patterns
                            case 'balance limit': balanceLimit.push({contract: fileName, line: rows[j][1]}); break
                            case 'checks-effects-interaction': checks.push({contract: fileName, line: rows[j][1]}); break
                            case 'emergency stop': emergency.push({contract: fileName, line: rows[j][1]}); break
                            case 'mutex': mutex.push({contract: fileName, line: rows[j][1]}); break
                            case 'rate limit': rateLimit.push({contract: fileName, line: rows[j][1]}); break
                            case 'secure ether transfer': secureEther.push({contract: fileName, line: rows[j][1]}); break
                            case 'speed bump': speedBump.push({contract: fileName, line: rows[j][1]}); break
                            default: lapses.push({contract: fileName, pattern: rows[j][0], line: rows[j][1]}); break
                        }
                    }
            })
        }
    })
}

function onlyUnique(value, index, self){
    return self.indexOf(value) === index;
}

function getUniques(arr){
    let newArr = []
    for (let i=0; i<arr.length; i++) {
        newArr.push(arr[i].contract)
    }
    return newArr.filter(onlyUnique);
}

getPatterns()

setTimeout(async () => {
    let csv = {}
    //Authorization
    console.log("Access restriction: "+accessRest.length+' - contracts: '+getUniques(accessRest).length); csv = new ObjectsToCsv(accessRest); await csv.toDisk(folder_auth+'accessRestriction.csv', { append: false })
    console.log("Multiple authorization: "+multsig.length+' - contracts: '+getUniques(multsig).length); csv = new ObjectsToCsv(multsig); await csv.toDisk(folder_auth+'multipleAuthorization.csv', { append: false })
    console.log("Ownership: "+owner.length+' - contracts: '+getUniques(owner).length); csv = new ObjectsToCsv(owner); await csv.toDisk(folder_auth+'ownership.csv', { append: false })
    //Control
    console.log("Commit amd reveal: "+commitReveal.length+' - contracts: '+getUniques(commitReveal).length); csv = new ObjectsToCsv(commitReveal); await csv.toDisk(folder_control+'commitReveal.csv', { append: false })
    console.log("Guard check: "+guardCheck.length+' - contracts: '+getUniques(guardCheck).length); csv = new ObjectsToCsv(guardCheck); await csv.toDisk(folder_control+'guardCheck.csv', { append: false })
    console.log("Memory array building: "+memoryArray.length+' - contracts: '+getUniques(memoryArray).length); csv = new ObjectsToCsv(memoryArray); await csv.toDisk(folder_control+'memoryArrayBuilding.csv', { append: false })
    console.log("Oracle: "+oracle.length+' - contracts: '+getUniques(oracle).length); csv = new ObjectsToCsv(oracle); await csv.toDisk(folder_control+'oracle.csv', { append: false })
    console.log("Poll: "+poll.length+' - contracts: '+getUniques(poll).length); csv = new ObjectsToCsv(poll); await csv.toDisk(folder_control+'poll.csv', { append: false })
    console.log("Pull payment: "+pullPayment.length+' - contracts: '+getUniques(pullPayment).length); csv = new ObjectsToCsv(pullPayment); await csv.toDisk(folder_control+'pullPayment.csv', { append: false })
    console.log("Randomness: "+randomness.length+' - contracts: '+getUniques(randomness).length); csv = new ObjectsToCsv(randomness); await csv.toDisk(folder_control+'randomness.csv', { append: false })
    console.log("Safemath: "+safemath.length+' - contracts: '+getUniques(safemath).length); csv = new ObjectsToCsv(safemath); await csv.toDisk(folder_control+'safemath.csv', { append: false })
    console.log("State machine: "+stateMachine.length+' - contracts: '+getUniques(stateMachine).length); csv = new ObjectsToCsv(stateMachine); await csv.toDisk(folder_control+'stateMachine.csv', { append: false })
    console.log("String equality comparison: "+stringEqual.length+' - contracts: '+getUniques(stringEqual).length); csv = new ObjectsToCsv(stringEqual); await csv.toDisk(folder_control+'stringEqualityComparison.csv', { append: false })
    console.log("Tight variable packing: "+tightVar.length+' - contracts: '+getUniques(tightVar).length); csv = new ObjectsToCsv(tightVar); await csv.toDisk(folder_control+'tightVariablePacking.csv', { append: false })
    console.log("Token: "+token.length+' - contracts: '+getUniques(token).length); csv = new ObjectsToCsv(token); await csv.toDisk(folder_control+'token.csv', { append: false })
    //Maintenance
    console.log("Automatic deprecation: "+autoDep.length+' - contracts: '+getUniques(autoDep).length); csv = new ObjectsToCsv(autoDep); await csv.toDisk(folder_maint+'automaticDeprecation.csv', { append: false })
    console.log("Contract composer: "+composer.length+' - contracts: '+getUniques(composer).length); csv = new ObjectsToCsv(composer); await csv.toDisk(folder_maint+'contractComposer.csv', { append: false })
    console.log("Contract factory: "+factory.length+' - contracts: '+getUniques(factory).length); csv = new ObjectsToCsv(factory); await csv.toDisk(folder_maint+'contractFactory.csv', { append: false })
    console.log("Contract register: "+register.length+' - contracts: '+getUniques(register).length); csv = new ObjectsToCsv(register); await csv.toDisk(folder_maint+'contractRegister.csv', { append: false })
    console.log("Contract relay: "+relay.length+' - contracts: '+getUniques(relay).length); csv = new ObjectsToCsv(relay); await csv.toDisk(folder_maint+'contractRelay.csv', { append: false })
    console.log("Data segregation: "+segregation.length+' - contracts: '+getUniques(segregation).length); csv = new ObjectsToCsv(segregation); await csv.toDisk(folder_maint+'dataSegregation.csv', { append: false })
    console.log("Mortal: "+mortal.length+' - contracts: '+getUniques(mortal).length); csv = new ObjectsToCsv(mortal); await csv.toDisk(folder_maint+'mortal.csv', { append: false })
    console.log("Satellite: "+satellite.length+' - contracts: '+getUniques(satellite).length); csv = new ObjectsToCsv(satellite); await csv.toDisk(folder_maint+'satellite.csv', { append: false })
    //Security
    console.log("Balance Limit: "+balanceLimit.length+' - contracts: '+getUniques(balanceLimit).length); csv = new ObjectsToCsv(balanceLimit); await csv.toDisk(folder_sec+'balanceLimit.csv', { append: false })
    console.log("Checks-effects-interaction: "+checks.length+' - contracts: '+getUniques(checks).length); csv = new ObjectsToCsv(checks); await csv.toDisk(folder_sec+'checks-effects-interaction.csv', { append: false })
    console.log("Emergency stop: "+emergency.length+' - contracts: '+getUniques(emergency).length); csv = new ObjectsToCsv(emergency); await csv.toDisk(folder_sec+'emergencyStop.csv', { append: false })
    console.log("Mutex: "+mutex.length+' - contracts: '+getUniques(mutex).length); csv = new ObjectsToCsv(mutex); await csv.toDisk(folder_sec+'mutex.csv', { append: false })
    console.log("Rate limit: "+rateLimit.length+' - contracts: '+getUniques(rateLimit).length); csv = new ObjectsToCsv(rateLimit); await csv.toDisk(folder_sec+'rateLimit.csv', { append: false })
    console.log("Secure ether transfer: "+secureEther.length+' - contracts: '+getUniques(secureEther).length); csv = new ObjectsToCsv(secureEther); await csv.toDisk(folder_sec+'secureEtherTransfer.csv', { append: false })
    console.log("Speed bump: "+speedBump.length+' - contracts: '+getUniques(speedBump).length); csv = new ObjectsToCsv(speedBump); await csv.toDisk(folder_sec+'speedBump.csv', { append: false })
    //lapses
    console.log("Lapses: "+lapses.length); csv = new ObjectsToCsv(lapses); await csv.toDisk(folder_2+'lapses.csv', { append: false })
},1000)



