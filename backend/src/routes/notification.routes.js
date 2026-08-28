const express = require('express');
const {
  listNotifications,
  streamNotifications,
} = require('../controllers/notification.controller');

const router = express.Router();
router.get('/', listNotifications);
router.get('/stream', streamNotifications);

module.exports = router;
