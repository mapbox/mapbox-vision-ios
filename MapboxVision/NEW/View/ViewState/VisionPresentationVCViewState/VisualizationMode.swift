/**
 Mode that determines which type of events is currently being visualized.
 */
public enum VisualizationMode {

    /**
     Show a raw frame from a video source
     */
    case clear

    /**
     Show segmentation mask blended with a video frame
     */
    case segmentation

    /**
     Show detected objects with bounding boxes
     */
    case detection
}
