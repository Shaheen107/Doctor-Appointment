import SwiftUI

// MARK: - DoctorProfile Model
struct DoctorProfile: Identifiable, Codable {
    var id = UUID()
    var name: String
    var specialization: String
    var experience: Int
    var contact: String
}

// MARK: - Appointment Model
struct Appointment: Identifiable, Codable {
    var id = UUID()
    var doctorName: String
    var date: Date
    var time: String
    var status: String
}

// MARK: - AppointmentViewModel
class AppointmentViewModel: ObservableObject {
    @Published var doctors: [DoctorProfile] = []
    @Published var appointments: [Appointment] = []
    @Published var searchQuery: String = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showDeleteConfirmation = false
    @Published var doctorToDelete: IndexSet?
    @Published var appointmentToDelete: IndexSet?

    init() {
        loadDoctors()
        loadAppointments()
    }
    
    var filteredDoctors: [DoctorProfile] {
        if searchQuery.isEmpty {
            return doctors
        } else {
            return doctors.filter { $0.name.contains(searchQuery) || $0.specialization.contains(searchQuery) }
        }
    }
    
    func addDoctor(doctor: DoctorProfile) {
        if doctor.name.isEmpty || doctor.specialization.isEmpty || doctor.contact.isEmpty {
            alertMessage = "All fields are required!"
            showAlert = true
        } else {
            doctors.append(doctor)
            saveDoctors()
            alertMessage = "Doctor added successfully!"
            showAlert = true
        }
    }
    
    func updateDoctor(doctor: DoctorProfile) {
        if let index = doctors.firstIndex(where: { $0.id == doctor.id }) {
            doctors[index] = doctor
            saveDoctors()
            alertMessage = "Doctor updated successfully!"
            showAlert = true
        }
    }
    
    func deleteDoctor(at indexSet: IndexSet) {
        doctors.remove(atOffsets: indexSet)
        saveDoctors()
        alertMessage = "Doctor deleted successfully!"
        showAlert = true
    }
    
    func addAppointment(appointment: Appointment) {
        if appointment.doctorName.isEmpty || appointment.time.isEmpty {
            alertMessage = "Please select a valid time for the appointment!"
            showAlert = true
        } else {
            appointments.append(appointment)
            saveAppointments()
            alertMessage = "Appointment booked successfully!"
            showAlert = true
        }
    }
    
    func deleteAppointment(at indexSet: IndexSet) {
        appointments.remove(atOffsets: indexSet)
        saveAppointments()
        alertMessage = "Appointment deleted successfully!"
        showAlert = true
    }
    
    func saveDoctors() {
        if let encoded = try? JSONEncoder().encode(doctors) {
            UserDefaults.standard.set(encoded, forKey: "Doctors")
        }
    }
    
    func loadDoctors() {
        if let data = UserDefaults.standard.data(forKey: "Doctors") {
            if let decoded = try? JSONDecoder().decode([DoctorProfile].self, from: data) {
                self.doctors = decoded
            }
        }
    }
    
    func saveAppointments() {
        if let encoded = try? JSONEncoder().encode(appointments) {
            UserDefaults.standard.set(encoded, forKey: "Appointments")
        }
    }
    
    func loadAppointments() {
        if let data = UserDefaults.standard.data(forKey: "Appointments") {
            if let decoded = try? JSONDecoder().decode([Appointment].self, from: data) {
                self.appointments = decoded
            }
        }
    }
}

// MARK: - Doctor List View
struct DoctorListView: View {
    @ObservedObject var viewModel: AppointmentViewModel
    @State private var showingAddDoctorForm = false
    @State private var showingEditDoctorForm = false
    @State private var selectedDoctor: DoctorProfile?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    TextField("Search by name or specialization", text: $viewModel.searchQuery)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.bottom, 10)
                
                ZStack {
                    // Background text for empty state
                    if viewModel.filteredDoctors.isEmpty {
                        VStack {
                            Spacer()
                            Text("No doctors available. Tap + to add a new doctor.")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(viewModel.filteredDoctors) { doctor in
                                HStack {
                                    NavigationLink(destination: AppointmentBookingView(viewModel: viewModel, doctor: doctor)) {
                                        DoctorCardView(doctor: doctor)
                                    }
                                    Spacer()
                                    Button(action: {
                                        selectedDoctor = doctor
                                        showingEditDoctorForm = true
                                    }) {
                                        Image(systemName: "pencil.circle")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.trailing, 10)
                                }
                            }
                            .onDelete { indexSet in
                                viewModel.doctorToDelete = indexSet
                                viewModel.showDeleteConfirmation = true
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
                .navigationTitle("Doctors")
                .navigationBarItems(trailing: Button(action: {
                    showingAddDoctorForm = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                })
                .sheet(isPresented: $showingAddDoctorForm) {
                    AddDoctorView(viewModel: viewModel, isPresented: $showingAddDoctorForm)
                }
                .sheet(isPresented: $showingEditDoctorForm) {
                    if let selectedDoctor = selectedDoctor {
                        EditDoctorView(viewModel: viewModel, isPresented: $showingEditDoctorForm, doctor: selectedDoctor)
                    }
                }
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text("Message"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
                }
                .alert(isPresented: $viewModel.showDeleteConfirmation) {
                    Alert(
                        title: Text("Delete Doctor"),
                        message: Text("Are you sure you want to delete this doctor?"),
                        primaryButton: .destructive(Text("Delete")) {
                            if let indexSet = viewModel.doctorToDelete {
                                viewModel.deleteDoctor(at: indexSet)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
}

// MARK: - Doctor Card View
struct DoctorCardView: View {
    var doctor: DoctorProfile
    
    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .padding(10)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(doctor.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Specialization: \(doctor.specialization)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Experience: \(doctor.experience) years")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
    }
}

// MARK: - Add Doctor View
struct AddDoctorView: View {
    @ObservedObject var viewModel: AppointmentViewModel
    @Binding var isPresented: Bool
    @State private var doctorName = ""
    @State private var specialization = ""
    @State private var experience = 0
    @State private var contact = ""

    // Reset form fields after adding a doctor
    private func resetFormFields() {
        doctorName = ""
        specialization = ""
        experience = 0
        contact = ""
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Doctor Details").font(.headline).foregroundColor(.white).padding().background(Color.blue).cornerRadius(8)) {
                    TextField("Doctor Name", text: $doctorName)
                    TextField("Specialization", text: $specialization)
                    TextField("Experience (years)", value: $experience, formatter: NumberFormatter())
                    TextField("Contact", text: $contact)
                }
            }
            .navigationBarTitle("Add Doctor", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                let newDoctor = DoctorProfile(name: doctorName, specialization: specialization, experience: experience, contact: contact)
                viewModel.addDoctor(doctor: newDoctor)
                resetFormFields() // Reset the form fields after saving
                isPresented = false
            })
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Message"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

// MARK: - Edit Doctor View
struct EditDoctorView: View {
    @ObservedObject var viewModel: AppointmentViewModel
    @Binding var isPresented: Bool
    @State var doctor: DoctorProfile
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Doctor Details").font(.headline).foregroundColor(.white).padding().background(Color.blue).cornerRadius(8)) {
                    TextField("Doctor Name", text: $doctor.name)
                    TextField("Specialization", text: $doctor.specialization)
                    TextField("Experience (years)", value: $doctor.experience, formatter: NumberFormatter())
                    TextField("Contact", text: $doctor.contact)
                }
            }
            .navigationBarTitle("Edit Doctor", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                viewModel.updateDoctor(doctor: doctor)
                isPresented = false
            })
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Message"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

// MARK: - Appointment Booking View
struct AppointmentBookingView: View {
    @ObservedObject var viewModel: AppointmentViewModel
    var doctor: DoctorProfile
    
    @State private var selectedDate = Date()
    @State private var selectedTime = ""
    @State private var showAlert = false
    
    let availableTimes = ["10:00 AM", "11:00 AM", "12:00 PM", "02:00 PM", "03:00 PM", "04:00 PM"]
    
    var body: some View {
        Form {
            Section(header: Text("Doctor Details").font(.headline).foregroundColor(.white).padding().background(Color.blue).cornerRadius(8)) {
                Text("Doctor: \(doctor.name)")
                Text("Specialization: \(doctor.specialization)")
                Text("Experience: \(doctor.experience) years")
            }
            
            Section(header: Text("Appointment Details").font(.headline).foregroundColor(.white).padding().background(Color.blue).cornerRadius(8)) {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                Picker("Select Time", selection: $selectedTime) {
                    ForEach(availableTimes, id: \.self) { time in
                        Text(time)
                    }
                }
            }
        }
        .navigationBarItems(trailing: Button("Book") {
            if selectedTime.isEmpty {
                viewModel.alertMessage = "Please select a valid time for the appointment!"
                viewModel.showAlert = true
            } else {
                let newAppointment = Appointment(doctorName: doctor.name, date: selectedDate, time: selectedTime, status: "Scheduled")
                viewModel.addAppointment(appointment: newAppointment)
            }
        })
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Message"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

// MARK: - Appointment History View
struct AppointmentHistoryView: View {
    @ObservedObject var viewModel: AppointmentViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.appointments.isEmpty {
                    Text("No appointments yet.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.appointments) { appointment in
                            VStack(alignment: .leading) {
                                Text("\(appointment.doctorName)")
                                    .font(.headline)
                                Text("Date: \(appointment.date, formatter: dateFormatter)")
                                    .font(.subheadline)
                                Text("Time: \(appointment.time)")
                                    .font(.subheadline)
                                Text("Status: \(appointment.status)")
                                    .font(.subheadline)
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.appointmentToDelete = indexSet
                            viewModel.showDeleteConfirmation = true
                        }
                    }
                    .navigationTitle("Appointment History")
                    .toolbar {
                        EditButton()
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Message"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $viewModel.showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Appointment"),
                    message: Text("Are you sure you want to delete this appointment?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let indexSet = viewModel.appointmentToDelete {
                            viewModel.deleteAppointment(at: indexSet)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

// MARK: - Date Formatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject var viewModel = AppointmentViewModel()
    
    var body: some View {
        TabView {
            DoctorListView(viewModel: viewModel)
                .tabItem {
                    Label("Doctors", systemImage: "person.3.fill")
                }
            
            AppointmentHistoryView(viewModel: viewModel)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
    }
}

// MARK: - Main App
@main
struct DoctorAppointmentApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
