import React, { useEffect, useState } from "react";
import './styles/App.css';
import twitterLogo from './assets/twitter-logo.svg';
import { ethers } from "ethers";
import contractAbi from './utils/contractABI.json';

import polygonLogo from './assets/polygonlogo.png';
import ethLogo from './assets/ethlogo.png';
import { networks } from './utils/networks';

// 常量
const TWITTER_HANDLE = 'kechuan_Office';
const TWITTER_LINK = `https://twitter.com/${TWITTER_HANDLE}`;

// 添加你将铸造的域
const tld = '.create';
//合约地址
const CONTRACT_ADDRESS = '0x5D621363D348A05971F2Ceeb6eCDaeF4EB30b265';
const addressd = '0x7A1FEDca9EF13CbfC2aF83Dd01D261ee6dba5E0d';
//let walletAddress = '';
const App = () => {
  const [currentAccount, setCurrentAccount] = useState('');
  const [network, setNetwork] = useState('');

  const [editing, setEditing] = useState(false);
  const [loading, setLoading] = useState(false);

  const [mints, setMints] = useState([]);
  const [owner, superCoder] = useState([]);

  // 添加一些状态数据属性
  const [domain, setDomain] = useState('');
  const [record, setRecord] = useState('');

  //连接钱包
  const connectWallet = async () => {
    try {
      const { ethereum } = window;

      if (!ethereum) {
        alert("get MetaMask -> https://metamask.io/");
        return;
      }

      const accounts = await ethereum.request({ method: 'eth_requestAccounts' });

      console.log("Connected", accounts[0]);
      setCurrentAccount(accounts[0]);
      {/*  this.walletAddress = accounts[0];
      alert(this.walletAddress);*/}
    } catch (error) {
      console.log(error);
    }
  }


  //检查钱包是否已经连接
  const checkIfWalletIsConnected = async () => {
    const { ethereum } = window;

    if (!ethereum) {
      console.log('Make sure you have metamask!');
      return;
    } else {
      console.log('有一个以太坊对象', ethereum);
    }

    const accounts = await ethereum.request({ method: 'eth_accounts' });

    if (accounts.length !== 0) {
      const account = accounts[0];
      console.log('找到一个授权账户:', account);
      setCurrentAccount(account);
    } else {
      console.log('没有找到授权帐户');
    }

    // 检查用户的网络链ID
    const chainId = await ethereum.request({ method: 'eth_chainId' });
    setNetwork(networks[chainId]);

    ethereum.on('chainChanged', handleChainChanged);

    //更改网络时刷新页面
    function handleChainChanged(_chainId) {
      window.location.reload();
    }
  };


  // 如果钱包还没有连接，创建一个函数来呈现
  const renderNotConnectedContainer = () => (
    <div className="connect-wallet-container">
      <img src="https://media.giphy.com/media/hWGI9TQGsKsdBcxRi5/giphy.gif" alt="gif" />

      {/* 在单击按钮时调用刚才编写的connectWallet函数 */}
      <button onClick={connectWallet} className="cta-button connect-wallet-button">
        connectWallet
    	</button>
    </div>
  );

  useEffect(() => {
    checkIfWalletIsConnected();
  }, [])


  //改变网络状态
  const switchNetwork = async () => {
    if (window.ethereum) {
      try {
        //尝试切换到Mumbai testnet
        await window.ethereum.request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId: '0x13881' }], // 检查networks.js中的十六进制网络id
        });
      } catch (error) {
        // 这个错误代码意味着我们想要的链没有被添加到MetaMask
        // 要求用户将其添加到MetaMask中
        if (error.code === 4902) {
          try {
            await window.ethereum.request({
              method: 'wallet_addEthereumChain',
              params: [
                {
                  chainId: '0x13881',
                  chainName: 'Polygon Mumbai Testnet',
                  rpcUrls: ['https://rpc-mumbai.maticvigil.com/'],
                  nativeCurrency: {
                    name: "Mumbai Matic",
                    symbol: "MATIC",
                    decimals: 18
                  },
                  blockExplorerUrls:
                    ["https://mumbai.polygonscan.com/"]
                },
              ],
            });
          } catch (error) {
            console.log(error);
          }
        }
        console.log(error);
      }
    } else {
      // 如果窗口没有找到以太坊，则MetaMask没有安装
      alert('MetaMask未安装。请安装它来使用这个应用程序: https://metamask.io/download.html');
    }
  }

  //铸造域名函数
  const mintDomain = async () => {

    // 如果域名为空，不能运行
    if (!domain) { return alert('域名不能为空！'); }
    // 如果域名太短，提醒用户
    if (domain.length < 3) {
      alert('域名长度至少为3个字符！');
      return;
    }
    if (domain.length > 10) {
      alert('域名长度不能超过10个字符！');
    }

    // 根据域名的长度计算价格(更改此以匹配您的合同)
    // 3 chars = 0.05 MATIC, 4 chars = 0.03 MATIC, 5 or more = 0.01 MATIC
    const price = domain.length === 3 ? '0.05' : domain.length === 4 ? '0.03' : '0.01';
    console.log("Minting 域名：", domain, "需支付：", price);

    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const contract = new ethers.Contract(CONTRACT_ADDRESS, contractAbi.abi, signer);

        console.log("正在调用metamask")
        let tx = await contract.register(domain, { value: ethers.utils.parseEther(price) });
        // 等待交易被执行
        const receipt = await tx.wait();

        // 检查交易是否成功完成
        if (receipt.status === 1) {
          alert("该域名成功铸造! https://mumbai.polygonscan.com/tx/" + tx.hash);
          console.log("签署铸造哈希：" + tx.hash);

          // 为域设置记录
          tx = await contract.setRecord(domain, record);
          await tx.wait();

          alert("增加的记录哈希! https://mumbai.polygonscan.com/tx/" + tx.hash);
          console.log("记录铸造哈希：" + tx.hash);
          // 2秒后调用fetchMints
          setTimeout(() => {
            fetchMints();
          }, 2000);

          setRecord('');
          setDomain('');

        } else {
          alert("交易失败，请重试！");
        }
      }
    } catch (error) {
      console.log(error);
    }
  }

  //1、合同中的所有域名；2、获得的每个域名的记录；3、获得的每个域名的所有者地址
  const fetchMints = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const contract = new ethers.Contract(CONTRACT_ADDRESS, contractAbi.abi, signer);

        // 从合约中获取所有域名
        const names = await contract.getAllNames();

        // 对于每个域名，获取记录和地址
        const mintRecords = await Promise.all(names.map(async (name) => {
          const mintRecord = await contract.records(name);
          const owner = await contract.domains(name);
          return {
            id: names.indexOf(name),
            name: name,
            record: mintRecord,
            owner: owner,
          };
        }));
        console.log(" 域名展示 ", mintRecords);
        setMints(mintRecords);
      }
    } catch (error) {
      console.log(error);
    }
  }
  // 当currentAccount或网络发生变化时，就会运行此命令
  useEffect(() => {
    if (network === 'Polygon Mumbai Testnet') {
      fetchMints();
    }
  }, [currentAccount, network]);


  //官方提取资金
  const draw_down = async () => {

    try {
      const { ethereum } = window;
      if (ethereum) {


        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const signer = provider.getSigner()
        const contract = new ethers.Contract(CONTRACT_ADDRESS, contractAbi.abi, signer);

        const balance = await ethers.provider.getBalance(CONTRACT_ADDRESS);
        console.log("Contract balance:", ethers.utils.formatEther(balance));
        try {
          txn = await contract.connect(superCoder).withdraw();
          await txn.wait();
        } catch (error) {
          console.log("Could not withdraw contract");
        }

        let ownerBalance = await ethers.provider.getBalance(owner.address);
        console.log("Balance of owner before withdrawal:", ethers.utils.formatEther(ownerBalance));

        txn = await contract.connect(signer).withdraw();
        await txn.wait();

        // 取回合约和owner的余额
        const contractBalance = await ethers.provider.getBalance(CONTRACT_ADDRESS);
        signerBalance = await ethers.provider.getBalance(signer.address);

        console.log("Contract balance after withdrawal:", ethers.utils.formatEther(contractBalance));
        console.log("Balance of owner after withdrawal:", ethers.utils.formatEther(signerBalance));

      }
    }

    catch (error) {
      console.log(error);
    }
  }


  //更新域名记录的信息
  const updateDomain = async () => {
    if (!record || !domain) { return }
    setLoading(true);
    console.log(" updateDomain:", domain, "with record", record);
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const contract = new ethers.Contract(CONTRACT_ADDRESS, contractAbi.abi, signer);

        let tx = await contract.setRecord(domain, record);
        await tx.wait();
        console.log("Record set https://mumbai.polygonscan.com/tx/" + tx.hash);

        fetchMints();
        setRecord('');
        setDomain('');
      }
    } catch (error) {
      console.log(error);
    }
    setLoading(false);
  }

  // renderMints渲染函数
  const renderMints = () => {
    if (currentAccount && mints.length > 0) {
      return (
        <div className="mint-container">
          <p className="subtitle"> Recently minted domains!</p>
          <div className="mint-list">
            {mints.map((mint, index) => {
              return (
                <div className="mint-item" key={index}>
                  <div className='mint-row'>
                    <a className="link" href={`https://testnets.opensea.io/assets/mumbai/${CONTRACT_ADDRESS}/${mint.id}`} target="_blank" rel="noopener noreferrer">
                      <p className="underlined">{' '}{mint.name}
                        {tld}{' '}</p>
                    </a>
                    {/* 如果mint。所有者是currentAccount，添加一个“编辑”按钮*/}
                    {mint.owner.toLowerCase() === currentAccount.toLowerCase() ?
                      <button className="edit-button" onClick={() => editRecord(mint.name)}>
                        <img className="edit-icon" src="https://img.icons8.com/metro/26/000000/pencil.png" alt="Edit button" />
                      </button>
                      :
                      null
                    }
                  </div>
                  <p> {mint.record} </p>
                </div>)
            })}
          </div>
        </div>);
    }
  };


  // 进入编辑模式，并显示编辑按钮!
  const editRecord = (name) => {
    console.log("editRecord:", name);
    setEditing(true);
    setDomain(name);
  }

  // renderInputForm函数；如果应用程序处于编辑模式，我们将呈现两个不同的按钮。该Set record按钮将调用我们编写的更新函数，而取消按钮将使我们退出编辑模式。
  const renderInputForm = () => {

    if (network !== 'Polygon Mumbai Testnet') {
      return (
        <div className="connect-wallet-container">
          <p>Please connect Polygon Mumbai Testnet</p>
          <button className='cta-button mint-button' onClick={switchNetwork}>switchNetwork</button>
        </div>
      );
    }

    return (
      <div className="form-container">
        <div className="first-row">
          <input
            type="text"
            value={domain}
            placeholder='domain'
            onChange={e => setDomain(e.target.value)}
          />
          <p className='tld'> {tld} </p>
        </div>

        <input
          type="text"
          value={record}
          placeholder='Add something special'
          onChange={e => setRecord(e.target.value)}
        />

        {/*提取资金*/}

        <button className='cta-button mint-button' disabled={loading} onClick={draw_down}> withdraw </button>


        {/* 如果编辑变量为真，返回“设置记录”和“取消”按钮 */}
        {editing ? (
          <div className="button-container">

            {/* 这将调用我们刚刚创建的updateDomain函数*/}
            <button className='cta-button mint-button' disabled={loading} onClick={updateDomain}>
              Set record
          </button>

            {/* 这将让我们通过将editing设置为false来摆脱编辑模式*/}
            <button className='cta-button mint-button' onClick={() => { setEditing(false) }}>
              Cancel
          </button>

            {/*}     <button className='cta-button mint-button' disabled={loading} onClick={null}>
              Set data
					</button>*/}
          </div>
        ) : (
            // 调用mintDomain函数,mint按钮
            <button className='cta-button mint-button' disabled={loading} onClick={mintDomain}>
              mint
            </button>

          )}

      </div>
    );
  }

  useEffect(() => {
    checkIfWalletIsConnected();
  }, []);

  return (
    <div className="App">
      <div className="container">
        <div className="header-container">
          <header>
            {/*显示文案*/}
            <div className="left">
              <p className="title">Krt Name Service</p>
              <p className="subtitle">Immortal decentralized domain name on Ploygon!</p>
            </div>

            {/*显示徽标和钱包连接状态*/}
            <div className="right">
              <img alt="Network logo" className="logo" src={
                network.includes("Polygon") ? polygonLogo : ethLogo} />
              {currentAccount ? <p> Wallet: {currentAccount.slice(0, 6)}...{currentAccount.slice(-4)} </p> : <p> Not connected </p>}
            </div>
          </header>
        </div>

        {!currentAccount && renderNotConnectedContainer()}
        {/* 如果连接了帐户，则呈现输入表单 */}
        {currentAccount && renderInputForm()}
        {mints && renderMints()}

        <div className="footer-container">
          <img alt="Twitter Logo" className="twitter-logo" src={twitterLogo} />
          <a
            className="footer-text"
            href={TWITTER_LINK}
            target="_blank"
            rel="noreferrer"
          >{`built with @${TWITTER_HANDLE}`}</a>
        </div>
      </div>
    </div>
  );
};

export default App;
