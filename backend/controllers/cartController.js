// cartController.js
import userModel from "../models/userModel.js";

// Add items to user cart
const addToCart = async (req, res) => {
    try {

        const userId = req.userId;      // ⭐ from middleware
        const itemid = req.body.itemId;

        let userData = await userModel.findById(userId);

        let cartdata = userData.cartdata || {};

        if (!cartdata[itemid]) {
            cartdata[itemid] = 1;
        } else {
            cartdata[itemid] += 1;
        }

        await userModel.findByIdAndUpdate(userId, { cartdata });

        res.json({ success: true, message: "Added to Cart" });

    } catch (error) {
        console.log(error);
        res.json({ success: false, message: "Error" });
    }
};

// Remove items from user cart
const removeFromCart = async (req, res) => {
    try {
        const userId = req.userId;      // ⭐ from middleware
        const itemid = req.body.itemId;

        let userData = await userModel.findById(userId);

        let cartdata = userData.cartdata || {};

        if (cartdata[itemid] > 0) {
            cartdata[itemid] -= 1;
        }
        await userModel.findByIdAndUpdate(userId, { cartdata });
        res.json({ success: true, message: "Removed from Cart" });
    } catch (error) {
        console.log(error);
        res.json({ success: false, message: "Error" });
    }
};

// Fetch user cart data
const getCart = async (req, res) => {
    try {
        const userId = req.userId;      // ⭐ from middleware
        const itemid = req.body.itemId;

        let userData = await userModel.findById(userId);

        let cartdata = userData.cartdata || {};
        res.json({ success: true, cartdata });
    } catch (error) {
        console.log(error);
        res.json({ success: false, message: "Error" });
    }
};

export { addToCart, removeFromCart, getCart };