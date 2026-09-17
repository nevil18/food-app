import mongoose from "mongoose"
import dotenv from "dotenv"
import { food_list } from "./foodData.js"
import foodModel from "./models/foodModel.js"

dotenv.config()

const seedFoods = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI)

    await foodModel.deleteMany()
    await foodModel.insertMany(food_list)

    console.log("🔥 32 foods inserted successfully")
    process.exit()
  } 
  catch (err) {
    console.log(err)
    process.exit(1)
  }
}

seedFoods()
