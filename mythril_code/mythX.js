const fs = require('fs')
const path = require('path')
const glob = require("glob")
const { Client } = require ('mythxjs')
var Buffer = require('buffer/').Buffer

const folder = 'D:/Dropbox/0_isep/TDMEI/collectSmartContractsFromEtherscan/test/'
//metamask address ou email 
//const address = '0x98AE42952D8CA5d979B1a638429eFd5b05E5838B' //const address = '0x0000000000000000000000000000000000000000'
const address = 'jmesmoorish@gmail.com' //mail ou metamask address da conta de https://dashboard.mythx.io
const pass = 'B@rr0sas' //pass da conta de https://dashboard.mythx.io
const toolName = 'MythXJS' // outro exemplo: "testTool"
const environment = 'https://api.mythx.io/v1'
//opcional
const  MYTHX_API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiIyZmNiOTdmOS0xOThiLTQ1NDAtODEwNy1iZTY2ZTVhZjk2YTkiLCJpYXQiOjE1ODg4NDU1NDkuMDY3LCJpc3MiOiJNeXRoWCBBUEkiLCJleHAiOjE5MDQ0MjE1NDkuMDYsInVzZXJJZCI6IjVlYjMyZmMzNGZhNGM5MDAxOWI5YmVlOCJ9.TWA_Q_e9DIV42zA-tCc8E59aKci9yrzMZhbLFl9OohA'
const mythx = new Client(address, pass, toolName, environment) //const mythx = new Client(address, pass, toolName, environment, MYTHX_API_KEY)

const login = async () => {
  const tokens = await mythx.login()
  console.log('Tokens: ', tokens)
}

login()

const getFiles = () => {
    let code = []
    //glob("**/*.js", options, function (er, files) { // options is optional
    glob(folder+'*.sol', async (er, files) => {
        console.log('Total files:' +files.length)
        for (let i=0; i<files.length; i++) {
            let fileName = path.basename(files[i]) //remove path from file name
            let fileName2 = path.basename(files[i], '.sol') // remove extension .sol from file name
            //let contractCode = fs.readFileSync(files[i]).toString().split("\n") // para criar array de strings
            let contractCode = fs.readFileSync(files[i]).toString()
            //let contractCode = fs.readFileSync(files[i])
            //contractCode = Buffer.from(contractCode, 'utf8'); // = let contractCode = fs.readFileSync(files[i])
            //for(j in contractCode) {console.log(contractCode[j]);}
            //let contractCode = "pragma solidity 0.4.24;\n contract SimpleDAO {\n mapping (address => uint) public credit;\n function donate(address to) payable public{ credit[to] += msg.value;}\n}"
            console.log('Code: '+contractCode[0])
            console.log(typeof contractCode);
            console.log(typeof fileName);
            //let post = {sourceCode: contractCode, contractName: fileName} //para mythx.submitSourceCode(post)
            let post = {mainSource: contractCode, contractName: fileName} //para mythx.analyze(post)
            //post = JSON.stringify(post)
            let res = {}
            try {
              setTimeout(async () => {
                //res = await mythx.analyze(post)
                res = await mythx.submitSourceCode(post)
                console.log(i+' - '+res) //JSON.stringify(res, null, '\t')
              },2000)
              fs.writeFileSync(fileName2+'.json', res)
            } catch(err) {
              console.error('Erro no for: '+err);
            }
        }
    })
}

setTimeout(async () => {
  getFiles()
},3000)





