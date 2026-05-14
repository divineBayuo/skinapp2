// -----------------------
// NTD INFO CARD
// -----------------------
import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';

class NtdInfo {
  final String name;
  final String aka;
  final String description;
  final String pathogen;
  final List<String> tags;
  final Color chipColor;
  final Color chipText;

  const NtdInfo({
    required this.name,
    required this.aka,
    required this.description,
    required this.pathogen,
    required this.tags,
    required this.chipColor,
    required this.chipText,
  });
}

final List<NtdInfo> kNtdInfoList = [
  NtdInfo(
    name: 'Buruli Ulcer',
    aka: 'Mycobacterium ulcerans',
    description:
        'Painless necrotising skin ulcers caused by Mycobacterium ulcerans. '
        'Begins as a nodule or painless plaque before ulcerating. '
        'Early treatment with antibiotics is curative.',
    pathogen: 'Bacteria',
    tags: ['Ulcer', 'Limb', 'Africa'],
    chipColor: const Color(0xFFE6F1FB),
    chipText: const Color(0xFF0C447C),
  ),
  NtdInfo(
    name: 'Leprosy',
    aka: "Hansen's disease",
    description:
        'Chronic bacterial infection by Mycobacterium leprae affecting skin, '
        'peripheral nerves and mucosa. Causes hypopigmented skin patches, '
        'numbness and deformity if untreated.',
    pathogen: 'Bacteria',
    tags: ['Skin Patch', 'Nerve', 'Worldwide'],
    chipColor: const Color(0xFFEEEDFE),
    chipText: const Color(0xFF3C3489),
  ),
  NtdInfo(
    name: 'Yaws',
    aka: 'Treponema pallidum pertenue',
    description:
        'Highly contagious bacterial disease of skin and bone. '
        'Begins as a painless papilloma that can ulcerate. '
        'Single-dose azithromycin is curative.',
    pathogen: 'Bacteria',
    tags: ['Papilloma', 'Children', 'Tropical'],
    chipColor: const Color(0xFFE1F5EE),
    chipText: const Color(0xFF085041),
  ),
  NtdInfo(
    name: 'Cutaneous Leishmaniasis',
    aka: 'CL / Oriental sore',
    description:
        'Sandfly-transmitted parasitic disease causing skin ulcers, nodules '
        'and plaques. Usually self-healing but leaves scarring. '
        'Treatment with antimonials or miltefosine.',
    pathogen: 'Parasite',
    tags: ['Ulcer', 'Nodule', 'Sandfly'],
    chipColor: const Color(0xFFFAECE7),
    chipText: const Color(0xFF712B13),
  ),
  NtdInfo(
    name: 'Lymphatic Filariasis',
    aka: 'Elephantiasis',
    description:
        'Mosquito-borne nematode infection causing severe lymphoedema '
        'and skin thickening in limbs and genitalia. '
        'Preventable with annual mass drug administration.',
    pathogen: 'Parasite',
    tags: ['Oedema', 'Limb', 'Mosquito'],
    chipColor: const Color(0xFFFAEEDA),
    chipText: const Color(0xFF633806),
  ),
  NtdInfo(
    name: 'Onchocerciasis',
    aka: 'River blindness',
    description:
        'Blackfly-transmitted Onchocerca volvulus infection causing intense '
        'itching, skin nodules, depigmentation ("leopard skin") and blindness. '
        'Ivermectin MDA controls transmission.',
    pathogen: 'Parasite',
    tags: ['Nodule', 'Itching', 'Blackfly'],
    chipColor: const Color(0xFFEAF3DE),
    chipText: const Color(0xFF27500A),
  ),
  NtdInfo(
    name: 'Scabies',
    aka: 'Sarcoptes scabiei infestation',
    description:
        'Highly contagious mite infestation causing intense nocturnal itching '
        'and papular rash between fingers, wrists and body folds. '
        'Permethrin or oral ivermectin clears infection.',
    pathogen: 'Mite',
    tags: ['Papule', 'Contagious', 'Worldwide'],
    chipColor: const Color(0xFFFBEAF0),
    chipText: const Color(0xFF72243E),
  ),
  NtdInfo(
    name: 'Mycetoma',
    aka: 'Madura foot',
    description:
        'Bacterial or fungal infection of skin, subcutaneous tissue and bone. '
        'Presents as tumour-like swelling with sinus tracts discharging grains. '
        'Commonest on the foot.',
    pathogen: 'Bacteria/Fungal',
    tags: ['Osteomyelitis', 'Foot', 'Sinus Tracts'],
    chipColor: const Color(0xFFE6F1FB),
    chipText: const Color(0xFF185FA5),
  ),
  NtdInfo(
    name: 'Chromoblastomycosis',
    aka: 'Chromomycosis',
    description:
        'Chronic subcutaneous fungal infection from soil-dwelling fungi. '
        'Causes slowly growing verrucous plaques and nodules, mainly on lower limbs.',
    pathogen: 'Fungal',
    tags: ['Plaque', 'Nodule', 'Lower Limb'],
    chipColor: const Color(0xFFF1EFE8),
    chipText: const Color(0xFF444441),
  ),
  NtdInfo(
    name: 'Podoconiosis',
    aka: 'Non-filarial elephantiasis',
    description:
        'Non-infectious lymphoedema from long-term exposure to silica-rich '
        'volcanic soil through bare feet. Affects farming communities. '
        'Prevented by wearing shoes.',
    pathogen: 'Non-infectious',
    tags: ['Oedema', 'Foot', 'Barefoot Farmers'],
    chipColor: const Color(0xFFE1F5EE),
    chipText: const Color(0xFF0F6E56),
  ),
  NtdInfo(
    name: 'Tungiasis',
    aka: 'Jigger flea / Tunga penetrans',
    description:
        'Sand flea infestation causing painful nodules with a central black dot, '
        'mainly on feet and toes. Secondary bacterial infection is common. '
        'Mechanical removal is the treatment.',
    pathogen: 'Flea',
    tags: ['Nodule', 'Toe', 'Secondary Infection'],
    chipColor: const Color(0xFFFAECE7),
    chipText: const Color(0xFF993C1D),
  ),
  NtdInfo(
    name: 'Cutaneous Larva Migrans',
    aka: 'Creeping eruption',
    description:
        'Animal hookworm larva migrating beneath the epidermis, leaving '
        'an intensely itchy serpiginous track. Affects hands, feet and buttocks. '
        'Albendazole or ivermectin is curative.',
    pathogen: 'Parasite',
    tags: ['Serpiginous Track', 'Feet', 'Beaches'],
    chipColor: const Color(0xFFFAEEDA),
    chipText: const Color(0xFF854F0B),
  ),
];

// full-detail bottom sheet
void showNtdDetail(BuildContext context, NtdInfo ntd) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            // scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                children: [
                  // Pathogen chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ntd.chipColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ntd.pathogen,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ntd.chipText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Name
                  Text(
                    ntd.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Aka
                  Text(
                    ntd.aka,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  // full description
                  Text(
                    ntd.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ntd.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: ntd.chipColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: ntd.chipText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// --- Card widget -------------------------------------
class NtdInfoCard extends StatelessWidget {
  final NtdInfo ntd;
  const NtdInfoCard({super.key, required this.ntd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showNtdDetail(context, ntd),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // pathogen chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ntd.chipColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ntd.pathogen,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ntd.chipText,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // name
              Text(
                ntd.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),

              // aka
              Text(
                ntd.aka,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                ntd.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 10),

              // tap hints
              Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to read more',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Tags
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: ntd.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.fieldBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// horizontal scroll for home screen
class NtdInfoCardList extends StatelessWidget {
  const NtdInfoCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: kNtdInfoList.length,
        itemBuilder: (ctx, i) => NtdInfoCard(ntd: kNtdInfoList[i]),
      ),
    );
  }
}
