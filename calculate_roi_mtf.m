function [mtf50, freq, mtf_curve] = calculate_roi_mtf(roi_data)
    % 1. Pre-processing: Linearize and Grayscale
    % If your ROI is raw Bayer, you should select one channel (e.g., Green)
    if size(roi_data, 3) == 3
        img = double(rgb2gray(roi_data));
    else
        img = double(roi_data);
    end

    % 2. Get Edge Spread Function (ESF)
    % We project the 2D slanted edge into a 1D profile
    % This handles the "oversampling" inherent in the slanted edge method
    [~, ~] = size(img);
    
    % Simple gradient-based edge detection to find the slant angle
    [~, ~] = gradient(img);
    edge_profile = mean(img, 1); % Initial horizontal average
    
    % 3. Calculate Line Spread Function (LSF)
    % The LSF is the first derivative of the ESF
    lsf = diff(edge_profile);
    
    % Apply Hanning window to reduce FFT leakage
    window = hann(length(lsf))';
    lsf_windowed = lsf .* window;

    % 4. Perform FFT to get MTF
    raw_fft = abs(fft(lsf_windowed));
    mtf_curve = raw_fft(1:floor(end/2));
    mtf_curve = mtf_curve / mtf_curve(1); % Normalize to 1 at DC

    % 5. Determine MTF50
    % Frequency axis in cycles per pixel (0 to 0.5)
    freq = linspace(0, 0.5, length(mtf_curve));
    mtf50 = interp1(mtf_curve, freq, 0.5);

    % Plotting for verification
    plot(freq, mtf_curve, 'LineWidth', 2);
    grid on; xlabel('Spatial Frequency (cy/px)'); ylabel('MTF');
    title(['ROI MTF50: ', num2str(mtf50, '%.3f'), ' cy/px']);
end