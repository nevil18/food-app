import jwt from "jsonwebtoken";

const authMiddleware = (req, res, next) => {
    try {
        // get token from headers
        const token = req.headers.token;

        // check token exists
        if (!token) {
            return res.json({
                success: false,
                message: "Not Authorized. Login Again."
            });
        }

        // verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // store user id in request object
        req.userId = decoded.id;

        // go to next controller
        next();

    } catch (error) {
        console.log(error);
        res.json({
            success: false,
            message: "Invalid Token"
        });
    }
};

export default authMiddleware;