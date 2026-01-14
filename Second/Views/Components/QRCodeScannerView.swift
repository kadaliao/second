//
//  QRCodeScannerView.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import SwiftUI
import AVFoundation
import UIKit

/// QR Code scanner view using AVFoundation
struct QRCodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, presentationMode: presentationMode)
    }

    class Coordinator: NSObject, QRScannerDelegate {
        @Binding var scannedCode: String?
        var presentationMode: Binding<PresentationMode>

        init(scannedCode: Binding<String?>, presentationMode: Binding<PresentationMode>) {
            _scannedCode = scannedCode
            self.presentationMode = presentationMode
        }

        func didScanCode(_ code: String) {
            scannedCode = code
            presentationMode.wrappedValue.dismiss()
        }
    }
}

protocol QRScannerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // 添加扫描框和遮罩
        addScanningOverlay()

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    private func addScanningOverlay() {
        // 创建半透明遮罩层
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // 扫描框大小和位置
        let scanSize: CGFloat = min(view.bounds.width, view.bounds.height) * 0.65
        let scanFrame = CGRect(
            x: (view.bounds.width - scanSize) / 2,
            y: (view.bounds.height - scanSize) / 2,
            width: scanSize,
            height: scanSize
        )

        // 在遮罩层上挖一个透明的扫描区域
        let path = UIBezierPath(rect: overlayView.bounds)
        let scanPath = UIBezierPath(roundedRect: scanFrame, cornerRadius: 16)
        path.append(scanPath)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer

        view.addSubview(overlayView)

        // 添加扫描框边框
        let borderLayer = CAShapeLayer()
        borderLayer.path = scanPath.cgPath
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 3
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.cornerRadius = 16
        view.layer.addSublayer(borderLayer)

        // 添加四个角的装饰
        let cornerLength: CGFloat = 20
        let cornerWidth: CGFloat = 3

        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            // 左上角
            (CGPoint(x: scanFrame.minX, y: scanFrame.minY + cornerLength),
             CGPoint(x: scanFrame.minX, y: scanFrame.minY),
             CGPoint(x: scanFrame.minX + cornerLength, y: scanFrame.minY)),
            // 右上角
            (CGPoint(x: scanFrame.maxX - cornerLength, y: scanFrame.minY),
             CGPoint(x: scanFrame.maxX, y: scanFrame.minY),
             CGPoint(x: scanFrame.maxX, y: scanFrame.minY + cornerLength)),
            // 左下角
            (CGPoint(x: scanFrame.minX, y: scanFrame.maxY - cornerLength),
             CGPoint(x: scanFrame.minX, y: scanFrame.maxY),
             CGPoint(x: scanFrame.minX + cornerLength, y: scanFrame.maxY)),
            // 右下角
            (CGPoint(x: scanFrame.maxX - cornerLength, y: scanFrame.maxY),
             CGPoint(x: scanFrame.maxX, y: scanFrame.maxY),
             CGPoint(x: scanFrame.maxX, y: scanFrame.maxY - cornerLength))
        ]

        for corner in corners {
            let cornerPath = UIBezierPath()
            cornerPath.move(to: corner.0)
            cornerPath.addLine(to: corner.1)
            cornerPath.addLine(to: corner.2)

            let cornerLayer = CAShapeLayer()
            cornerLayer.path = cornerPath.cgPath
            cornerLayer.strokeColor = UIColor.systemBlue.cgColor
            cornerLayer.lineWidth = cornerWidth
            cornerLayer.lineCap = .round
            cornerLayer.fillColor = UIColor.clear.cgColor
            view.layer.addSublayer(cornerLayer)
        }
    }

    func failed() {
        let ac = UIAlertController(title: "扫描不可用", message: "你的设备不支持扫描二维码", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "确定", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanCode(stringValue)
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
