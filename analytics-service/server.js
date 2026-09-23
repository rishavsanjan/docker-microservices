import express from "express"

const app = express();

const PORT = 6001;

app.use(express.json());

const clicks = new Map();

app.get("/", (req, res) => {
  res.json({
    service: "Analytics Service",
    status: "running"
  });
});

app.post("/track", (req, res) => {
  const { shortId } = req.body;

  if (!shortId) {
    return res.status(400).json({
      error: "shortId is required"
    });
  }

  const currentClicks = clicks.get(shortId) || 0;

  clicks.set(shortId, currentClicks + 1);

  res.json({
    shortId,
    clicks: currentClicks + 1
  });
});

app.get("/stats/:shortId", (req, res) => {
  const shortId = req.params.shortId;

  res.json({
    shortId,
    clicks: clicks.get(shortId) || 0
  });
});

app.listen(PORT, () => {
  console.log(`Analytics service running on port ${PORT}`);
});