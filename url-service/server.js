

import express from "express";
import { Pool } from "pg";
import { createClient } from "redis";

const app = express();

app.use(express.json());

const PORT = 5000;


const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});



const redisClient = createClient({
  url: "redis://redis:6379"
});

redisClient.on("error", (error) => {
  console.error("Redis error:", error);
});



app.get("/", (req, res) => {
  res.json({
    service: "URL Service",
    status: "running"
  });
});



app.post("/shorten", async (req, res) => {
  try {
    const { url } = req.body;

    if (!url) {
      return res.status(400).json({
        message: "URL is required"
      });
    }

    const shortId = Math.random()
      .toString(36)
      .substring(2, 8);

    const result = await pool.query(
      `
      INSERT INTO urls (short_id, original_url)
      VALUES ($1, $2)
      RETURNING *
      `,
      [shortId, url]
    );

    res.status(201).json({
      shortId: result.rows[0].short_id,
      originalUrl: result.rows[0].original_url
    });

  } catch (error) {
    console.error("Error creating short URL:", error);

    res.status(500).json({
      message: "Internal server error"
    });
  }
});


app.get("/url/:id", async (req, res) => {
  const { id } = req.params;

  try {


    const cachedUrl = await redisClient.get(`url:${id}`);

    if (cachedUrl) {
      console.log("CACHE HIT");

      try {
        await fetch("http://analytics-service:6001/track", {
          method: "POST",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            shortId: id
          })
        });
      } catch (error) {
        console.error("Analytics service unavailable");
      }

      return res.json({
        originalUrl: cachedUrl,
        source: "redis"
      });
    }

    console.log("CACHE MISS");


    const result = await pool.query(
      `
      SELECT original_url
      FROM urls
      WHERE short_id = $1
      `,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "URL not found"
      });
    }

    const originalUrl = result.rows[0].original_url;


    await redisClient.set(
      `url:${id}`,
      originalUrl
    );

   

    try {
      await fetch("http://analytics-service:6000/track", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          shortId: id
        })
      });
    } catch (error) {
      console.error("Analytics service unavailable");
    }


    res.json({
      originalUrl,
      source: "postgres"
    });

  } catch (error) {
    console.error("Error retrieving URL:", error);

    res.status(500).json({
      message: "Internal server error"
    });
  }
});



app.listen(PORT, () => {
    console.log(`URL service running on port ${PORT}`);
})
