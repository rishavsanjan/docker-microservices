import express from "express"

const app = express();
const PORT = 5000;

app.use(express.json())

const urls = new Map();

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
    const url = urls.get(req.params.id)

    if (!url) {
        return res.status(404).json({
            error: "URL not found"
        });
    }

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
        url
    });
})

app.listen(PORT, () => {
    console.log(`URL service running on port ${PORT}`);
})

