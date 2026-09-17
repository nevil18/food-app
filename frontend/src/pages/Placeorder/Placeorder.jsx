import React, { useContext } from 'react'
import './Placeorder.css'
import { StoreContext } from '../../Context/storeContext'
import { useState } from 'react';
import axios from 'axios';
import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

const Placeorder = () => {

  const { gettotalcartamount, token, food_list, cartitems, url } = useContext(StoreContext);
  const [data, setdata] = useState({
    firstname: "",
    lastname: "",
    email: "",
    street: "",
    city: "",
    state: "",
    zipcode: "",
    country: "",
    phone: ""
  })

  const onchangehandler = (event) => {
    const name = event.target.name;
    const value = event.target.value;
    setdata(data => ({ ...data, [name]: value }))
  }

  const place_order = async (event) => {
    event.preventDefault();
    let orderitem = [];
    food_list.map((item) => {
      if (cartitems[item._id] > 0) {
        let iteminfo = {
          ...item,
          quantity: cartitems[item._id]
        };
        orderitem.push(iteminfo);
      }
    })

    let orderdata = {
      address: data,
      items: orderitem,
      amount: gettotalcartamount() + 2,
    }
    let response = await axios.post(url + "/api/order/place", orderdata, { headers: { token } })
    if (response.data.success) {
      const { session_url } = response.data;
      window.location.replace(session_url);
    }
    else {
      alert("Error")
    }
  }

  const navigate = useNavigate();

  useEffect(()=>{
    if(!token){
      navigate("/cart")
    }
    else if(gettotalcartamount()===0){
      navigate("/cart")
    }
  })

  return (
    <form onSubmit={place_order} className="place-order">
      <div className="place-order-left">
        <p className="title">Delivery Information</p>
        <div className="mutli-fields">
          <input required name='firstname' onChange={onchangehandler} value={data.firstname} type="text" placeholder='First name' />
          <input required name='lastname' onChange={onchangehandler} value={data.lastname} type="text" placeholder='Last name' />
        </div>
        <input required name='email' onChange={onchangehandler} value={data.email} type="email" placeholder='Email Address' />
        <input required name='street' onChange={onchangehandler} value={data.street} type="text" placeholder='Street' />
        <div className="mutli-fields">
          <input required name='city' onChange={onchangehandler} value={data.city} type="text" placeholder='City' />
          <input required name='state' onChange={onchangehandler} value={data.state} type="text" placeholder='State' />
        </div>
        <div className="mutli-fields">
          <input required name='zipcode' onChange={onchangehandler} value={data.zipcode} type="text" placeholder='Zip code' />
          <input required name='country' onChange={onchangehandler} value={data.country} type="text" placeholder='Country' />
        </div>
        <input required name='phone' onChange={onchangehandler} value={data.phone} type="text" placeholder='phone' />
      </div>

      <div className="place-order-right">
        <div className="cart-total">
          <h2>Cart Totals</h2>
          <div>
            <div className="cart-total-details">
              <p>Subtotal</p>
              <p>${gettotalcartamount()}</p>
            </div>
            <div className="cart-total-details">
              <p>Delivery Fee</p>
              <p>${gettotalcartamount() === 0 ? 0 : 2}</p>
            </div>
            <div className="cart-total-details">
              <b>Total</b>
              <b>${gettotalcartamount() === 0 ? 0 : gettotalcartamount() + 2}</b>
            </div>
          </div>
          <button type='submit'>PROCEED TO PAYMENT</button>
        </div>
      </div>
    </form>
  )
}

export default Placeorder
