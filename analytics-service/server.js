import express from "express"
import { createClient } from "redis";


const app = express();

const PORT = 6001;

app.use(express.json());


const redisClient = createClient({
  url:"redis://redis:6379"
})

redisClient.on("error", (error) => {
  console.error("Redis error:", error);
});

const clicks = new Map();

app.get("/", (req, res) => {
  res.json({
    service: "Analytics Service",
    status: "running"
  });
});

app.post("/track", async(req, res) => {
  try {
    const { shortId } = req.body;
    if (!shortId) {
        return res.status(400).json({
        error: "shortId is required"
    });
    }
    const key = `clicks:${shortId}`;
    const clicks = await redisClient.incr(key)
    res.json({
      shortId,
      clicks
    });
  } catch (error) {
    console.error("Error tracking click:", error);

    res.status(500).json({
      message: "Internal server error"
    });
  }
  
});

app.get("/stats/:shortId", async  (req, res) => {

  try {
      const shortId = req.params.shortId;
      const key = `clicks:${shortId}`;
      const clicks = await redisClient.get(key)
      res.json({
        shortId,
        clicks: Number(clicks) || 0
      });
  } catch (error) {
    console.error("Error getting statistics: ", error);

    res.status(500).json({
      message: "Internal server error..."
    });
  }

});

await redisClient.connect()
console.log('Redis client running')

app.listen(PORT, () => {
  console.log(`Analytics service running on port ${PORT}`);
});