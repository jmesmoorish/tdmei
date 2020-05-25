const fs = require('fs')
const neatCsv = require('neat-csv')
const ObjectsToCsv = require('objects-to-csv')
const moment = require('moment')
const axios = require('axios')
const apiKey = 'SD89E5TADQC6UMMT5MMA4ZPH6Z4SPJYRBZ'
const startDate = moment("01/03/2020 00:00", "D/M/YYYY hh:mm").unix()
console.log('Start date Unix - '+startDate)
const endDate = moment("31/03/2020 23:59", "D/M/YYYY hh:mm").unix()
console.log('End date Unix - '+endDate)
const minTransactions = 99
let list = []
let startBlock = 9581791 // ''
let endBlock = 9782309 // ''
let transactions = [];

fs.readFile('export-verified-contractaddress-opensource-license.csv', async (err, data) => {
     if (err) {
       console.error('Error: '+err)
       return
     }
     //console.log(await neatCsv(data))
     list = await neatCsv(data)
})

const getBlockNumber = async (unixDate) => {
    try {
        //const res = await axios.get('https://api.etherscan.io/api?module=block&action=getblocknobytime&timestamp='+unixDate+'&closest=before&apikey='+apiKey)
        //console.log(res.data)
        return await axios.get('https://api.etherscan.io/api?module=block&action=getblocknobytime&timestamp='+unixDate+'&closest=before&apikey='+apiKey)
    } catch (err) {
        console.error(err)
    }
}

const getStartBlockNumber = async () => {
    const res = await getBlockNumber(startDate)
    startBlock = res.data.result
}

const getEndBlockNumber = async () => {
    const res = await getBlockNumber(endDate)
    endBlock = res.data.result
}

//getStartBlockNumber()
//getEndBlockNumber()

//const list2 = ["0xbe14536f8285e33d04203db65b61e4d1fe24f881", "0x9b3eb3b22dc2c29e878d7766276a86a8395fb56d"]

const loadTransactions = async () => {
    console.log('Start Block - '+startBlock)
    console.log('End Block - '+endBlock)
    try {
        //for (let i = 200; i<300; i++) {
        for (let i = 5861; i<list.length; i++) {
            let res = await axios.get('http://api.etherscan.io/api?module=account&action=txlist&address='+list[i].ContractAddress+'&startblock='+startBlock+'&endblock='+endBlock+'&sort=asc&apikey='+apiKey)
            console.log(i+' - '+res.data.result.length)
            if (res.data.result.length > minTransactions){
                //transactions[i] = {name: list[i].ContractName, address: list[i].ContractAddress, txcount: res.data.result.length}
                let obj = []
                obj[0] = {index: i, name: list[i].ContractName, address: list[i].ContractAddress, txcount: res.data.result.length} 
                transactions.push(obj[0])
                let csv = new ObjectsToCsv(obj) // so funciona com arrays de objetos
                await csv.toDisk('selectedAddresses.csv', { append: true })
            }
        }
    } catch (err) {
        console.error('Error: '+err)
    }
    //const csv = new ObjectsToCsv(transactions)
    //await csv.toDisk('selectedAddresses.csv')
    //await csv.toDisk('selectedAddresses.csv', { append: true })
}

setTimeout(() => {
    //console.log(list[0])
    //console.log(list[5933])
    //startBlock = '0'
    //endBlock = '9763096' // 29MAR20
    loadTransactions()
},1000)


