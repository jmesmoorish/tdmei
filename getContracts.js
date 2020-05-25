const fs = require('fs')
const neatCsv = require('neat-csv')
const axios = require('axios')
const apiKey = 'SD89E5TADQC6UMMT5MMA4ZPH6Z4SPJYRBZ'
let list = []
let contracts = []

fs.readFile('selectedAddresses.csv', async (err, data) => {
    if (err) {
      console.error('Error: '+err)
      return
    }
    //console.log(await neatCsv(data))
    list = await neatCsv(data)
})

const loadContracts = async () => {
   
    try {
        for (let i = 333; i<list.length; i++) {
            let res = await axios.get('https://api.etherscan.io/api?module=contract&action=getsourcecode&address='+list[i].address+'&apikey='+apiKey)
            contracts[i] = {name: list[i].name, code: res.data.result[0].SourceCode}
            fs.writeFileSync('./collectedContracts/'+contracts[i].name+'_'+list[i].index+'.sol', contracts[i].code);
            console.log(i+' - '+list[i].name)
        }
        //console.log('Contracts: '+contracts)
        console.log("The files were saved!");
    } catch (err) {
        console.error('Error: '+err)
    }

    //for (let i = 0; i<contracts.length; i++) {
    //    fs.writeFileSync('./collectedContracts/'+contracts[i].name+'_'+contracts[i].index+'.sol', contracts[i].code);
    //}
}


setTimeout(() => {
    //console.log(list)
    loadContracts()
},1000)


