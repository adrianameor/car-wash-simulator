function car_wash_simulator()
    % Number of cars
    num_cars = input('Enter the number of cars: ');


    % Type of random number generator
    rng_type = input('Enter the type of random number generator (rand/lcg/uni/expo): ', 's');


    % Predefined inter-arrival and service times
    inter_arrival_times = [3, 6, 9, 12, 15, 18, 21]; % 7 inter-arrival times
    service_times = [10, 20, 30, 40, 50, 60]; % 6 service times per wash bay
    
    % Service types
    service_types = {'normal', 'premium'};
    
    % Calculate probabilities and CDFs for inter-arrival times
    [inter_arrival_probs, inter_arrival_cdf, inter_arrival_ranges] = generate_prob_cdf_range(7);





    % Generate events for each car
    events(num_cars) = struct('car', [], 'arrival_time', [], 'rn_inter_arrival_time', [], 'inter_arrival_time', [], ...
                              'service_type', [], 'service_bay', [], 'service_time', [], ...
                              'rn_service_time', [], 'service_start_time', [], 'service_end_time', [], ...
                              'waiting_time', [], 'time_in_system', []);
    current_time = 0;
    last_service_end_time = zeros(3, 1);  % Track the end time of the last service in each bay


    
service_cdfs = cell(3, 1);
service_ranges = cell(3, 1);
for bay = 1:3   
    [service_probs, service_cdf, service_range] = generate_prob_cdf_range_service_times(6);
    service_cdfs{bay} = service_cdf;
    service_ranges{bay} = service_range;
    
    % Print the table for service times
    fprintf('\nService Times for Wash Bay %d:\n', bay);
    disp('Service Time (minutes) | Random Probability | CDF  | Range');
    for i = 1:length(service_times)
        fprintf('%22d | %18.2f | %.2f | %d - %d\n', ...
                service_times(i), service_probs(i), service_cdf(i), service_range(i, 1), service_range(i, 2));
    end
end


    
    
for car = 1:num_cars
    if car == 1
        rn_inter_arrival_time = 0; % No need for RN in the first iteration
        inter_arrival_time = 0;
        arrival_time = current_time;
    else
        rn_inter_arrival_time = generate_random_number(rng_type);  % Generate RN using selected RNG
        inter_arrival_time = floor(get_random_value_from_cdf(rn_inter_arrival_time / 100, inter_arrival_cdf, inter_arrival_times));
    end


    arrival_time = current_time + inter_arrival_time;
    [service_type, base_time, time_variation] = get_service_type(service_types);
    rn_service_time = generate_random_number(rng_type);  % Generate RN using selected RNG


    selected_bay = NaN;
    selected_service_start_time = NaN;
    min_service_end_time = inf;  % Initialize with a large value


    % Check all bays for availability
    for bay = 1:3
        if last_service_end_time(bay) <= arrival_time
            service_start_time = arrival_time;
            selected_bay = bay;
            selected_service_start_time = service_start_time;
            break;  % Found an available bay, no need to check further
        else
            if last_service_end_time(bay) < min_service_end_time
                min_service_end_time = last_service_end_time(bay);
                selected_bay = bay;
                selected_service_start_time = min_service_end_time;  % Service starts after previous one ends
            end
        end
    end


    % Correctly determine service time based on the selected bay
    service_time = floor(get_random_value_from_cdf(rn_service_time / 100, service_cdfs{selected_bay}, service_times));


    events(car).car = car;
    events(car).arrival_time = arrival_time;
    events(car).rn_inter_arrival_time = rn_inter_arrival_time;
    events(car).inter_arrival_time = inter_arrival_time;
    events(car).service_type = service_type;
    events(car).service_bay = selected_bay;
    events(car).service_time = service_time;
    events(car).rn_service_time = rn_service_time;
    events(car).service_start_time = selected_service_start_time;
    events(car).service_end_time = round((selected_service_start_time + service_time) * 100) / 100;
    events(car).waiting_time = round((selected_service_start_time - arrival_time) * 100) / 100;
    events(car).time_in_system = round(((selected_service_start_time + service_time) - arrival_time) * 100) / 100;
    
    last_service_end_time(selected_bay) = events(car).service_end_time;
    current_time = arrival_time;
end


    
        % Print inter-arrival times table
    fprintf('\nInterarrival Times:\n');
    disp('Interarrival Time (minutes) | Probability | CDF  | Range');
    for i = 1:length(inter_arrival_times)
        fprintf('%27d | %11.2f | %4.2f | %d - %d\n', ...
                inter_arrival_times(i), inter_arrival_probs(i), inter_arrival_cdf(i), inter_arrival_ranges(i, 1), inter_arrival_ranges(i, 2));
    end 
    
    % Calculate and display car wash service types
    normal_count = sum(strcmp({events.service_type}, 'normal'));
    premium_count = sum(strcmp({events.service_type}, 'premium'));
    service_type_counts = [normal_count, premium_count];
    [service_type_probs, service_type_cdf, service_type_ranges] = generate_custom_prob_cdf_range(service_type_counts, service_type_counts);
    
    fprintf('\nCar Wash Service Types:\n');
    disp('Service Type           | Probability | CDF  | Range');
    for i = 1:length(service_types)
        fprintf('%-22s | %.2f        | %.2f | %d - %d\n', ...
                service_types{i}, service_type_probs(i), service_type_cdf(i), service_type_ranges(i, 1), service_type_ranges(i, 2));
    end
    
    
    % Display the results
    fprintf('\nSimulation Results:\n');
    fprintf(' Car  | Arrival:  | RN Inter-arrival:  | Inter-arrival: | Service Start: | Departure: | Service Type:\n');


    for i = 1:length(events)
        event = events(i);
        fprintf('%5d | %9.1f | %18.0f | %14.1f | %14.1f | %10.1f | %s\n', ...
               event.car, event.arrival_time, event.rn_inter_arrival_time, event.inter_arrival_time, event.service_start_time, event.service_end_time, event.service_type);
    end
   
    
    % Extract service times for each wash bay
service_times_bay1 = [events([events.service_bay] == 1).service_time];
service_times_bay2 = [events([events.service_bay] == 2).service_time];
service_times_bay3 = [events([events.service_bay] == 3).service_time];

% Create a figure for histograms
figure;

% Create histogram for Wash Bay 1
subplot(1, 3, 1);
hist(service_times_bay1, 10); % 10 bins for simplicity
title('Wash Bay 1');
xlabel('Service Time');
ylabel('Frequency');

% Create a figure for histograms
figure;

% Create histogram for Wash Bay 2
subplot(1, 3, 2);
hist(service_times_bay2, 10); % 10 bins for simplicity
title('Wash Bay 2');
xlabel('Service Time');
ylabel('Frequency');

% Create a figure for histograms
figure;

% Create histogram for Wash Bay 3
subplot(1, 3, 3);
hist(service_times_bay3, 10); % 10 bins for simplicity
title('Wash Bay 3');
xlabel('Service Time');
ylabel('Frequency');
 


% Calculate Details for Wash Bay
for bay = 1:3
    fprintf('\nDetails for Wash Bay %d:\n', bay);
    disp('Car # | RN for Service Time | Service Time | Time Service Begins | Time Service Ends | Waiting Time | Time Spent in System');
    for i = 1:length(events)
        event = events(i);
        if event.service_bay == bay
            fprintf('%5d | %19.0f | %12.2f | %19.2f | %17.2f | %12.2f | %20.2f\n', ...
                    event.car, event.rn_service_time, event.service_time, event.service_start_time, event.service_end_time, event.waiting_time, event.time_in_system);
        end
    end


   
end



fprintf('\nMessage Exhibition:\n');


% Initialize counters and queues for each wash bay
last_service_end_time = zeros(3, 1);  % Track the end time of the last service in each bay


for i = 1:num_cars
    event = events(i);
    
    % Display arrival event
    fprintf('\nArrival of Car %d at minute %.0f and queue at counter %d\n', event.car, event.arrival_time, event.service_bay);
    
    % Display waiting time if any
    if event.waiting_time > 0
        fprintf('Car %d has to wait for %.0f minutes\n', event.car, event.waiting_time);
    end
    
    % Display service start event
    fprintf('Service for Car %d started at minute %.0f at Wash Bay %d\n', event.car, event.service_start_time, event.service_bay);
    
    % Display departure event
    fprintf('Departure of Car %d at minute %.0f from Wash Bay %d\n', event.car, event.service_end_time, event.service_bay);
    
    % Update the last service end time for the bay
    last_service_end_time(event.service_bay) = event.service_end_time;
end






    % Evaluate the results
    average_waiting_time = mean([events.waiting_time]);
    average_arrival_time = mean([events.arrival_time]);
    average_inter_arrival_time = mean([events.inter_arrival_time]);
    average_time_in_system = mean([events.time_in_system]);
    probability_waiting = mean([events.waiting_time] > 0);
    average_service_times = [0, 0, 0];
    for bay = 1:3
        average_service_times(bay) = mean([events([events.service_bay] == bay).service_time]);
    end
    
    fprintf('\nEvaluation:\n');
    fprintf('Average Waiting Time: %.6f\n', average_waiting_time);
    fprintf('Average Arrival Time: %.6f\n', average_arrival_time);    
    fprintf('Average Inter-Arrival Time: %.6f\n', average_inter_arrival_time);
    fprintf('Average Time in System: %.6f\n', average_time_in_system);
    fprintf('Probability of Waiting: %.6f\n', probability_waiting);
    for bay = 1:3
        fprintf('Average Service Time for Wash Bay %d: %.6f\n', bay, average_service_times(bay));
    end
end


function random_number = generate_random_number(rng_type)
    switch rng_type
        case 'rand'
            random_number = round(rand() * 100);
        case 'lcg'
            random_number = lcg_random_numbers();
        case 'uni'
            random_number = rand_uniform();
        case 'expo'
            random_number = expo_random_number();
        otherwise
            error('Invalid RNG type. Please choose from (rand/lcg/uni/expo).');
    end
end


function random_numbers = lcg_random_numbers()
    % This function is for random number generator for LCG method
    
    seed = floor(rand() * 100); % Initial seed value (randomly chosen)
    a = 102; % Multiplier
    c = 13; % Increment
    m = 101; % Modulus
    
    % Generate the random number and ensure it's in the range [0, 100]
    random_numbers = mod(mod(a * seed + c, m), 100) + 1;


end



function random_number = rand_uniform()
    
    %set value for interval [a,b]
    a = 1; 
    b = 100; 
    
    i = 0;
    while i < 1
        
        %generate sequence of rn for for every i(step)
        sequence = rand();
        
        %generate random number for uniform distribution
        %rounding random number using round function
        rand_num = round(a+((b-a)*sequence));
        
        %check if random number equal to zero
        if rand_num > 0
            random_number = abs(rand_num);
            i = i + 1;
        end
    end
end


function random_number = expo_random_number()
    
    %set value for lamda
    lamda = 5;
    
    i = 0;
    while i < 1
        
        %generate sequence of rn for for every i(step)
        sequence = rand();
        
        %generate random number for exponential distribution
        rand_num = (-1/lamda)*log(1-sequence);
        
        %rounding the random number to obtain integer using round function
        rand_num = max(1, round(rand_num*100));


        
        %check if random number equal to zero
        if rand_num > 0
            random_number = abs(rand_num);
            i = i + 1;
        end
    end
end


function value = get_random_value_from_cdf(rn, cdf, values)
    index = find(rn <= cdf, 1);  % Remove the tolerance
    if isempty(index)
        index = length(cdf);  % Handle edge case where rn might be slightly above the last cdf value
    end
    value = values(index);
end





function [service_type, base_time, time_variation] = get_service_type(service_types)
    rn_service_type = rand();
    if rn_service_type <= 0.8
        service_type = service_types{1}; % normal
        base_time = 5;
        time_variation = 2;
    else
        service_type = service_types{2}; % premium
        base_time = 10;
        time_variation = 3;
    end
end


function probs = generate_probabilities(n)
    probs = rand(1, n); 
    probs = probs / sum(probs); 
end


function [probs, cdf, ranges] = generate_prob_cdf_range(n)
    probs = generate_probabilities(n);
    cdf = cumsum(probs);
    ranges = zeros(n, 2);
    range_start = 1;
    for i = 1:n
        range_end = round(cdf(i) * 100);
        ranges(i, :) = [range_start, range_end];
        range_start = range_end + 1;
    end
    ranges(end, 2) = 100;  % Ensure the last range ends exactly at 100
end


function [probs, cdf, ranges] = generate_prob_cdf_range_service_times(n)
    probs = generate_probabilities(n);
    cdf = cumsum(probs);
    ranges = zeros(n, 2);
    for i = 1:n
        if i == 1
            ranges(i, :) = [1, round(cdf(i) * 100)];
        else
            ranges(i, :) = [round(cdf(i-1) * 100) + 1, round(cdf(i) * 100)];
        end
    end
end







function [probs, cdf, ranges] = generate_custom_prob_cdf_range(actual_counts, possible_values)
    total = sum(actual_counts);
    probs = actual_counts / total;
    cdf = cumsum(probs); 
    ranges = zeros(length(possible_values), 2); 
    for i = 1:length(possible_values)
        if i == 1
            ranges(i, :) = [1, round(cdf(i) * 100)];
        else
            ranges(i, :) = [round(cdf(i-1) * 100) + 1, round(cdf(i) * 100)];
        end
    end
end