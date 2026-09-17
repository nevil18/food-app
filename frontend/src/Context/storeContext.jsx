import { createContext, useEffect, useState } from "react";
import axios from 'axios'
export const StoreContext = createContext(null)

const StoreContextProvider = (props) => {

    const [cartitems, setcartitems] = useState({})
    const [token, settoken] = useState("")
    const url = ""
    const [food_list, setfoodlist] = useState([])

    const addToCart = async (itemId) => {
        if (!cartitems[itemId]) {
            setcartitems((prev) => ({ ...prev, [itemId]: 1 }))
        } else {
            setcartitems((prev) => ({ ...prev, [itemId]: prev[itemId] + 1 }))
        }
        if (token) {
            await axios.post(url + "/api/cart/add", { itemId }, { headers: { token } })
        }
    }

    const removeFromCart = async (itemId) => {
        setcartitems((prev) => ({ ...prev, [itemId]: prev[itemId] - 1 }))
        if (token) {
            await axios.post(url + "/api/cart/remove", { itemId }, { headers: { token } })
        }
    }

    const gettotalcartamount = () => {
        let totalamount = 0;
        for (const item in cartitems) {
            if (cartitems[item] > 0) {
                let iteminfo = food_list.find((product) => product._id === item);
                if (iteminfo) {  // Guard: skip stale cart items not in food_list
                    totalamount += iteminfo.price * cartitems[item];
                }
            }
        }
        return totalamount;
    }

    const loadcartdata = async (token) => {
        const response = await axios.post(url + "/api/cart/get", {}, { headers: { token } })
        setcartitems(response.data.cartdata || {})
    }

    const fetchfoodlist = async () => {
        const response = await axios.get(url + '/api/food/list');
        // Sanitize price: MongoDB Decimal128 comes as {$numberDecimal: "12"} — convert to plain number
        const sanitized = response.data.data.map(item => ({
            ...item,
            price: parseFloat(item.price?.$numberDecimal ?? item.price)
        }));
        setfoodlist(sanitized);
    }

    useEffect(() => {
        async function loaddata() {
            await fetchfoodlist();
            if (localStorage.getItem("token")) {
                settoken(localStorage.getItem("token"))
                await loadcartdata(localStorage.getItem("token"));
            }
        }
        loaddata();
    }, [])

    const contextvalue = {
        food_list,
        cartitems,
        setcartitems,
        addToCart,
        removeFromCart,
        gettotalcartamount,
        url,
        token,
        settoken
    }

    return (
        <StoreContext.Provider value={contextvalue}>
            {props.children}
        </StoreContext.Provider>
    )
}

export default StoreContextProvider;
