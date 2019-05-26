protocol DetectionViewPresenterInput: AnyObject {
    func present(detections: [BasicDetection], with image: UIImage)
}

protocol DetectionViewPresenterOutput: AnyObject {
    func display(detectionViewModels: [DetectionViewModel], with imageViewModel: ImageViewModel)
}

class DetectionViewPresenter {
    private weak var output: DetectionViewPresenterOutput!
}

extension DetectionViewPresenter: DetectionViewPresenterInput {
    func present(detections: [BasicDetection], with image: UIImage)
    {
        // NOTE: Format the response from the Interactor and pass the result back to the View Controller

        var viewModels: [DetectionViewModel] = []
        let imageViewModel = ImageViewModel(image: image)

        for basicDetection in detections {
            let titleText = basicDetection.objectType.title.uppercased()
            let titleFont = UIFont(name: "AvenirNextCondensed-Bold", size: 11)!
            let titleTextSize = titleText.size(withAttributes: [NSAttributedString.Key.font: titleFont])
            let labelViewModel = LabelViewModel(frame: basicDetection.boundingBox,
                                                text: basicDetection.objectType.title.uppercased(),
                                                textFont: titleFont,
                                                textAlignment: .center,
                                                backgroundColor: UIColor.black.withAlphaComponent(0.53),
                                                textColor: basicDetection.objectType.color)

            let labelHeight: CGFloat = 18
            let labelSidePadding: CGFloat = 5
            let bboxViewModel = BoundingBoxViewModel(frame: CGRect(x: labelViewModel.frame.origin.x,
                                                                   y: labelViewModel.frame.origin.y - labelHeight,
                                                                   width: titleTextSize.width + 2 * labelSidePadding,
                                                                   height: labelHeight),
                                                     borderWidth: 3.0,
                                                     backgroundColor: .clear,
                                                     borderColor: basicDetection.objectType.color.cgColor)
            let detectionViewModel = DetectionViewModel(label: labelViewModel, boundingBox: bboxViewModel)
            viewModels.append(detectionViewModel)

            output.display(detectionViewModels: viewModels, with: imageViewModel)
        }
    }
}
