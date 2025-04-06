const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'info.battleactivity@gmail.com',
    pass: 'zwxy uvio zppx rgwg'
  }
});

exports.sendemail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const feedbackMailOptions = {
    from: 'info.battleactivity@gmail.com',
    to: 'info.battleactivity@gmail.com',
    subject: `Feedback: ${data.subject}`,
    text: `Von: ${data.name} (${data.email})\n\n${data.message}`
  };

  const confirmationMailOptions = {
    from: 'info.battleactivity@gmail.com',
    to: data.email,
    subject: 'Vielen Dank für dein Feedback!',
    text: 'Vielen Dank für dein Feedback! Wir schätzen deine Meinung sehr und werden sie nutzen, um die App weiter zu verbessern.\n\nMit freundlichen Grüßen,\nDein BattleActivity Team'
  };

  try {
    await transporter.sendMail(feedbackMailOptions);
    await transporter.sendMail(confirmationMailOptions);
    return { success: true };
  } catch (error) {
    console.error('Error sending email:', error);
    throw new functions.https.HttpsError('internal', 'Mail delivery failed');
  }
});
