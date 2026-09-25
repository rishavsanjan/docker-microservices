import express from "express"
import {createClient} from "redis"

const app = express();
const PORT = 5000;

app.use(express.json())

const urls = new Map();

const redisClient = createClient({
  url: "redis://redis:6379"
});

redisClient.on("error", (err) => {
  console.error("Redis error:", err);
});

await redisClient.connect();

app.get("/", (req, res) => {
    res.json({
        service: "URL Service",
        staus: "Running"
    })
})


app.post("/shorten", (req, res) => {
    const { url } = req.body;

    if (!url) {
        return res.status(400).json({
            error: "URL is required"
        });
    }

    const id = Math.random().toString(36).substring(2, 8);

    urls.set(id, url);

    res.status(201).json({
        shortId: id,
        url
    });
})


app.get("/url/:id", async (req, res) => {
    const shortId = req.params.id;
    const url = urls.get(req.params.id);

    const cachedUrl = await redisClient.get(`url:${shortId}`);

    if (cachedUrl) {
        console.log("Cache hit for URL:", cachedUrl);
        return res.json({
            originalUrl: cachedUrl,
            source: "redis"
        });
    }
    
    console.log("CACHE MISS for URL:", url);

    if (!url) {
        return res.status(404).json({
            error: "URL not found"
        });
    }

    const result = await pool.query(
    "SELECT original_url FROM urls WHERE short_id = $1",
    [id]
  );

     const originalUrl = result.rows[0].original_url;
    await redisClient.set(`url:${id}`, originalUrl);

    try {
        await fetch("http://analytics-service:6001/track", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                shortId
            })
        });
    } catch (error) {
        console.error("Analytics service error:", error.message, error);
    }

    res.json({
        originalUrl,
        source: "postgres"
    });
})

app.listen(PORT, () => {
    console.log(`URL service running on port ${PORT}`);
})

