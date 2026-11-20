require('dotenv').config();
const Groq = require('groq-sdk');

async function testGroq() {
  const apiKey = process.env.GROQ_API_KEY;
  const model = process.env.GROQ_MODEL || 'llama3-8b-8192';

  console.log('Testing Groq API using SDK...');
  console.log('Model:', model);
  console.log('API Key:', apiKey ? 'Present (starts with ' + apiKey.substring(0, 4) + ')' : 'Missing');

  if (!apiKey) {
    console.error('Error: GROQ_API_KEY is not defined in .env');
    return;
  }

  const groq = new Groq({ apiKey });

  try {
    const chatCompletion = await groq.chat.completions.create({
      messages: [
        {
          role: 'user',
          content: 'Hello, are you working?'
        }
      ],
      model: model
    });

    console.log('SUCCESS! Groq API is working.');
    console.log('Response:', chatCompletion.choices[0]?.message?.content);
  } catch (error) {
    console.error('FAILURE! Groq API returned an error.');
    console.error('Status:', error.status);
    console.error('Error Details:', JSON.stringify(error, null, 2));
    
    if (error.status === 404) {
      console.log('\nTip: The model "' + model + '" was not found. Try using "llama3-8b-8192" or "mixtral-8x7b-32768".');
    }
  }
}

testGroq();
