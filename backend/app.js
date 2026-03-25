import express from 'express';
import 'dotenv/config';

const app = express();
app.use(express.json());

// тест
app.get('/', (req, res) => {
  res.send('ORS API работает 🚀');
});

app.post('/route', async (req, res) => {
  try {
    const { from, to, weight, height, width, length } = req.body;

    if (!from || !to) {
      return res.status(400).json({ error: 'from и to обязательны' });
    }

    // преобразуем "lat,lng" → [lng, lat]
    const parseCoords = (str) => {
      const [lat, lng] = str.split(',').map(Number);
      return [lng, lat];
    };

    const url = 'https://api.openrouteservice.org/v2/directions/driving-hgv';

    const body = {
      coordinates: [
        parseCoords(from),
        parseCoords(to)
      ],
      options: {
        vehicle_type: 'hgv',
        profile_params: {
          restrictions: {
            ...(height && { height }),
            ...(width && { width }),
            ...(length && { length }),
            ...(weight && { weight })
          }
        }
      }
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': process.env.ORS_API_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();

    res.json(data);

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.listen(3000, () => {
  console.log('🚀 Сервер на http://localhost:3000');
});