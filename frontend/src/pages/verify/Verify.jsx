import React from 'react'
import './Verify.css'
import { useContext } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom'
import { StoreContext } from '../../Context/storeContext';
import axios from 'axios';
import { useEffect } from 'react';

const Verify = () => {

  const [serachparams,setserachparams] = useSearchParams();
  const navigate = useNavigate();
  const success = serachparams.get("success")
  const orderid = serachparams.get("orderId")

  const {url} = useContext(StoreContext)
  const verifypayment = async () => {
    const response = await axios.post(url+"/api/order/verify",{success,orderId:orderid})
    if(response.data.success){
      navigate("/myorders");
    }
    else{
      navigate("/")
    }
  }

  useEffect(()=>{
    verifypayment();
  },[])

  return (
    <div className='verify'>
      <div className="spinner"></div>
    </div>
  )
}

export default Verify
