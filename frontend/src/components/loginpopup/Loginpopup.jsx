import React, { useContext, useState } from 'react'
import './Loginpopup.css'
import { assets } from '../../assets/assets'
import { StoreContext } from '../../Context/storeContext'
import axios from 'axios'

const Loginpopup = ({setshowlogin}) => {

    const {url,settoken} = useContext(StoreContext)

    const [currstate,setcurrstate] = useState("login")
    const [data,setdata] = useState({
      name:"",
      email:"",
      password:""
    })

    const onchangehandler = (event) => {
      const name = event.target.name;
      const value = event.target.value;
      setdata(data=>({...data,[name]:value}))
    }

    const onlogin = async (event) => {
      event.preventDefault();
      let newurl = url;
      if(currstate==='login'){
        newurl+='/api/user/login'
      }
      else{
        newurl+='/api/user/register'
      }

      const response = await axios.post(newurl,data);
      if(response.data.success){
        settoken(response.data.token)
        localStorage.setItem("token",response.data.token)
        setshowlogin(false)
      }
      else{
        alert(response.data.message)
      }
    }

  return (
    <div className='login-popup'>
      <form onSubmit={onlogin} className='login-popup-container'>
        <div className="login-popup-title">
            <h2>{currstate}</h2>
            <img onClick={()=>setshowlogin(false)} src={assets.cross_icon} alt="" />
        </div>
        <div className="login-popup-inputs">
            {currstate==="login"?<></>:<input type="text" name='name' onChange={onchangehandler} value={data.name} placeholder='your name' required/>}
            <input type="email" name='email' onChange={onchangehandler} value={data.email} placeholder='your email' required/>
            <input type="password" name='password' onChange={onchangehandler} value={data.password} placeholder='password' />
        </div>
        <button type='submit'>{currstate==="sign up"?"Create account":"Login"}</button>
        <div className='login-popup-condition'>
            <input type="checkbox" required/>
            <p>By continuing, i agree to terms of use & privacy policy.</p>
        </div>
        {currstate==="login"
        ?<p>Create new account? <span onClick={()=>setcurrstate("sign up")}>Click here</span></p>
        :<p>Already have an account? <span onClick={()=>setcurrstate("login")}>Login here</span></p>
        }
      </form>
    </div>
  )
}

export default Loginpopup
