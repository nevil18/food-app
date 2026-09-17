import foodModel from "../models/foodModel.js";
import fs from "fs";

// ADD FOOD
const addFood = async (req, res) => {
  try {
    let image_filename = req.file.filename;

    const food = new foodModel({
      name: req.body.name,
      description: req.body.description,
      price: Number(req.body.price),
      category: req.body.category,
      image: image_filename
    });

    await food.save();
    res.json({ success: true, message: "Food Added" });

  } catch (error) {
    console.log(error);
    res.json({ success: false, message: "Error adding food" });
  }
};

// LIST FOOD
const listfood = async (req, res) => {
    try {
        const foods = await foodModel.find({}).lean();

        const formattedFoods = foods.map(food => ({
            ...food,
            // Handles MongoDB Decimal128 ({$numberDecimal: "12"}), plain numbers, and strings
            price: parseFloat(food.price?.toString() ?? food.price)
        }));

        res.json({ success: true, data: formattedFoods });
    } catch (error) {
        console.log(error);
        res.json({ success: false, message: "Error fetching food list" });
    }
}

// REMOVE FOOD
const removefood = async (req, res) => {
  try {
    const id = req.body.id;

    const food = await foodModel.findById(id);
    if (!food) {
      return res.json({ success: false, message: "Food not found" });
    }

    fs.unlink(`uploads/${food.image}`, (err) => {
      if (err) console.log("Image delete error", err);
    });

    await foodModel.findByIdAndDelete(id);

    res.json({ success: true, message: "Food Removed" });

  } catch (err) {
    console.log(err);
    res.json({ success: false, message: "Error removing food" });
  }
};

export { addFood, listfood, removefood };