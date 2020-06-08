const fs = require('fs'); const neatCsv = require('neat-csv')
const ObjectsToCsv = require('objects-to-csv')
const moment = require('moment'); const axios = require('axios')
const apiKey = 'SD89E5TADQC6UMMT5MMA4ZPH6Z4SPJYRBZ'
const startDate = moment("01/03/2020 00:00", "D/M/YYYY hh:mm").unix()
const endDate = moment("31/03/2020 23:59", "D/M/YYYY hh:mm").unix()
const minTransactions = 99
let list = []; let transactions = []
let startBlock = '' // 9581791 -> hardcoded block corresponding "01/03/2020 00:00"
let endBlock = '' // 9782309 -> hardcoded block corresponding "31/03/2020 23:59"

fs.readFile('export-verified-contractaddress-opensource-license.csv', async (err, data) => {
    if (err) {console.error('Error: '+err); return}
    list = await neatCsv(data)
})

const getBlockNumber = async (unixDate) => {
    try {return await axios.get('https://api.etherscan.io/api?module=block&action=getblocknobytime&timestamp='+unixDate+'&closest=before&apikey='+apiKey)
    }catch (err) {console.error(err)}
}

const getStartBlockNumber = async () => {
    const res = await getBlockNumber(startDate)
    startBlock = res.data.result
}

const getEndBlockNumber = async () => {
    const res = await getBlockNumber(endDate)
    endBlock = res.data.result
}

getStartBlockNumber()
getEndBlockNumber()

const loadTransactions = async () => {
    try {
        for (let i = 0; i<list.length; i++) {
            let res = await axios.get('http://api.etherscan.io/api?module=account&action=txlist&address='+list[i].ContractAddress+'&startblock='+startBlock+'&endblock='+endBlock+'&sort=asc&apikey='+apiKey)
            console.log(i+' - '+res.data.result.length)
            if (res.data.result.length > minTransactions){
                let obj = []
                obj[0] = {index: i, name: list[i].ContractName, address: list[i].ContractAddress, txcount: res.data.result.length} 
                transactions.push(obj[0])
                let csv = new ObjectsToCsv(obj)
                await csv.toDisk('selectedAddresses.csv', { append: true })
            }
        }
    } catch (err) {
        console.error('Error: '+err)
    }
}

setTimeout(() => {loadTransactions()}, 1000)


