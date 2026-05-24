cat /home/claude/Photobooth/Photobooth/Services/PrintService.swift
Sortie

import UIKit
import SwiftUI

class PrintService: ObservableObject {
    @Published var printerAvailable: Bool = false
    @Published var printerName: String = ""
    @Published var lastError: String?
    @Published var isPrinting: Bool = false

    private var printerPickerController: UIPrinterPickerController?
    private var selectedPrinter: UIPrinter?

    // MARK: - Check Printer
    func checkPrinterAvailability() {
        DispatchQueue.main.async {
            if UIPrintInteractionController.isPrintingAvailable {
                self.printerAvailable = true
                self.printerName = self.selectedPrinter?.displayName ?? "AirPrint disponible"
            } else {
                self.printerAvailable = false
                self.printerName = ""
            }
        }
    }

    // MARK: - Print Image
    func print(image: UIImage, copies: Int, from viewController: UIViewController) {
        guard UIPrintInteractionController.isPrintingAvailable else {
            lastError = "L'impression n'est pas disponible sur cet appareil."
            return
        }

        isPrinting = true
        lastError = nil

        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Photobooth"
        printInfo.outputType = .photo
        printInfo.duplex = .none
        printController.printInfo = printInfo
        printController.printingItem = image
        printController.showsNumberOfCopies = false

        let completionHandler: UIPrintInteractionController.CompletionHandler = { [weak self] _, completed, error in
            DispatchQueue.main.async {
                self?.isPrinting = false
                if let error = error {
                    self?.lastError = error.localizedDescription
                } else if !completed {
                    self?.lastError = "Impression annulée."
                }
            }
        }

        if let printer = selectedPrinter {
            printController.print(to: printer, completionHandler: completionHandler)
        } else {
            printController.present(animated: true, completionHandler: completionHandler)
        }
    }

    // MARK: - Select Printer
    func showPrinterPicker(from viewController: UIViewController) {
        let picker = UIPrinterPickerController(initiallySelectedPrinter: selectedPrinter)
        printerPickerController = picker
        picker.present(animated: true) { [weak self] controller, userDidSelect, error in
            if userDidSelect, let printer = controller.selectedPrinter {
                DispatchQueue.main.async {
                    self?.selectedPrinter = printer
                    self?.printerName = printer.displayName
                    self?.printerAvailable = true
                }
            }
        }
    }
}

// MARK: - SwiftUI UIViewControllerRepresentable for Print
struct PrintButton: UIViewControllerRepresentable {
    let image: UIImage
    let copies: Int
    let printService: PrintService

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makePrint() {
        if let vc = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController {
            printService.print(image: image, copies: copies, from: vc)
        }
    }
}
