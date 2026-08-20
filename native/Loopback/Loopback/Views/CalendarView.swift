// CalendarView.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Month header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Weekday headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate), isToday: calendar.isDateInToday(date), hasMeetings: hasMeetings(on: date))
                            .onTapGesture { selectedDate = date }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            // Meetings for selected day
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Meetings on \(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))")
                        .font(.headline)
                    Spacer()
                    Button("New Meeting") { }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                .padding(.horizontal)
                
                // Mock meetings for selected day
                ForEach(mockMeetingsForDate(selectedDate)) { meeting in
                    MeetingRowCompact(meeting: meeting)
                }
                
                if mockMeetingsForDate(selectedDate).isEmpty {
                    Text("No meetings scheduled")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func hasMeetings(on date: Date) -> Bool {
        mockMeetingsForDate(date).count > 0
    }
    
    private func mockMeetingsForDate(_ date: Date) -> [MockMeeting] {
        let day = calendar.component(.day, from: date)
        switch day {
        case 1: return [MockMeeting(id: "1", title: "Team Standup", time: "09:00", platform: "zoom")]
        case 15: return [MockMeeting(id: "2", title: "Client Call", time: "14:00", platform: "teams")]
        case 20: return [
            MockMeeting(id: "3", title: "Sprint Planning", time: "10:00", platform: "meet"),
            MockMeeting(id: "4", title: "Budget Review", time: "15:00", platform: "zoom")
        ]
        default: return []
        }
    }
}

struct MockMeeting: Identifiable {
    let id: String
    let title: String
    let time: String
    let platform: String
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasMeetings: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.accentColor)
            } else if isToday {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 2)
            }
            
            Text("\(calendar.component(.day, from: date))")
                .font(.system(.body, design: .rounded))
                .fontWeight(isSelected || isToday ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : (isToday ? .accentColor : .primary))
            
            if hasMeetings && !isSelected {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .offset(y: 14)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct MeetingRowCompact: View {
    let meeting: MockMeeting
    
    var platformColor: Color {
        switch meeting.platform {
        case "zoom": return .blue
        case "teams": return .purple
        case "meet": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(platformColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(meeting.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(meeting.platform.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(meeting.time)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

#Preview {
    CalendarView()
}