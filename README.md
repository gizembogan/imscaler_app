# ImScaler

**ImScaler** is a mobile app developed with Flutter that enables users to upload face-containing photos, enhance them using an AI model, and save the results while preserving identity integrity. It focuses on providing a smooth, secure, and user-friendly photo processing experience.

The goal is to provide a **real-time, privacy-aware image super-resolution** pipeline that enhances facial images from 96×96 to 512×512 resolution **while preserving the subject’s identity**. This mobile application integrates the lightweight ONNX model and performs all inference **locally on the device** without requiring cloud access.

## 📱 Key Features

- Image selection from gallery with cropping
- On-device ONNX model inference (96×96 → 512×512 face upscaling)
- Identity-preserving output via pre-trained FaceNet embedding loss
- Firebase Authentication integration
- Minimal and responsive Flutter UI for smooth UX

## 🧠 Under the Hood

- **Model**: Lightweight UNet trained with pixel-wise MSE, VGG perceptual loss, and identity-aware FaceNet embedding loss
- **Deployment**: Converted to quantized INT8 ONNX format for edge deployment
- **Inference Time**: ~100 ms per image on mobile-class devices
- **Privacy**: No images are uploaded – all computations are fully offline
