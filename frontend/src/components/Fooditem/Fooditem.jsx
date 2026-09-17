import React, { useContext } from 'react'
import './Fooditem.css'
import { assets } from '../../assets/assets'
import { StoreContext } from '../../Context/storeContext'

const Fooditem = ({id, name, price, description, image}) => {

    const {cartitems, addToCart, removeFromCart, url} = useContext(StoreContext)

    return (
        <div>
            <div className="food-item">
                <div className="food-item-img-container">
                    <img src={url+"/images/"+image} alt="" className="food-item-image" />
                    {!cartitems?.[id]
                        ? <img className='add' onClick={()=>addToCart(id)} src={assets.add_icon_white}/>
                        : <div className='food-item-counter'>
                            <img src={assets.remove_icon_red} onClick={()=>removeFromCart(id)} alt="" />
                            <p>{cartitems[id]}</p>
                            <img src={assets.add_icon_green} onClick={()=>addToCart(id)} alt="" />
                          </div>
                    }
                </div>
                <div className="food-item-info">
                    <div className="food-item-name-rating">
                        <p>{name}</p>
                        <img src={assets.rating_starts} alt="" />
                    </div>
                    <p className='food-item-desc'>{description}</p>
                    <p className="food-item-price">${Number(price).toFixed(2)}</p>
                </div>
            </div>
        </div>
    )
}

export default Fooditem